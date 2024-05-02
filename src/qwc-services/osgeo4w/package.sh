export P=qwc-services
export V=1.3.4
export B=next
export MAINTAINER=JuergenFischer
export BUILDDEPENDS="python3-core python3-virtualenv"
export PACKAGES="qwc-services"
export SERVICENAME="Apache OSGeo4W Web server"

source ../../../scripts/build-helpers

startlog

cd ..

if [ -d $P-core ]; then
	cd $P-core
	git pull
else
	git clone https://github.com/$P/$P-core.git
	cd $P-core
fi

REPOS="qwc-config-service
       qwc-ogc-service
       qwc-services-core
       qwc-map-viewer
       qwc-config-db
       qwc-legend-service
       qwc-admin-gui
       qwc-db-auth
       qwc-data-service
       qwc-permalink-service
       qwc-print-service
       qwc-elevation-service
       qwc-fulltext-search-service
       qwc-ldap-auth
       qwc-registration-gui
       qwc-config-generator"

for repo in $REPOS; do
    if [ ! -d "${repo}" ]; then
        git clone https://github.com/qwc-services/$repo.git
    else
	cd $repo
	git reset --hard
	git pull
	cd ..
    fi
done

for i in qwc-admin-gui; do
	patch -d $i -p1 --dry-run <../osgeo4w/$i.diff
	patch -d $i -p1 <../osgeo4w/$i.diff
done

cd ../osgeo4w

cat <<EOF >postinstall.bat
setlocal enabledelayedexpansion

if exist "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis.conf" ren "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis.conf" httpd_qgis.conf.off-$P
if exist "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis-ltr.conf" ren "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis-ltr.conf" httpd_qgis-ltr.conf.off-$P
if not exist "%OSGEO4W_ROOT%\\apps\\$P\\projects" mkdir %OSGEO4W_ROOT%\\apps\\$P\\projects

set QGIS_PKG=qgis-ltr

if not exist "%OSGEO4W_ROOT%\\httpd.d\\httpd_$P.conf" (
	call "%OSGEO4W_ROOT%\\bin\\o4w_env.bat"
	for /f "usebackq tokens=1" %%a in (\`python3 -c "import secrets; print(secrets.token_urlsafe(36));"\`) do set JWT_SECURE_KEY=%%a

	textreplace -std ^
		-map @osgeo4w@ "%OSGEO4W_ROOT%" ^
		-map @o4wroot@ "%OSGEO4W_ROOT:\\=/%" ^
		-map @windir@ "%WINDIR%" ^
		-map @temp@ "%TEMP%" ^
		-map @userprofile@ "%USERPROFILE%" ^
		-map @qgispkg@ "%QGIS_PKG%" ^
		-map @securekey@ "!JWT_SECURE_KEY!" ^
		-t "%OSGEO4W_ROOT%/httpd.d/httpd_$P.conf"
)

if not exist "%OSGEO4W_ROOT%\\apps\\$P\\config\\in\\default\\tenantConfig.json" (
	textreplace -std ^
		-map @o4wroot@ %OSGEO4W_ROOT:\\=/% ^
		-t "%OSGEO4W_ROOT%/apps/$P/config/in/default/tenantConfig.json"
)

if not exist "%OSGEO4W_ROOT%\\apps\\$P\\config\\in\\default\\adminGuiConfig.json" (
	textreplace -std ^
		-map @o4wroot@ %OSGEO4W_ROOT:\\=/% ^
		-t "%OSGEO4W_ROOT%/apps/$P/config/in/default/adminGuiConfig.json"
)

if not exist "%OSGEO4W_ROOT%\\apps\\$P\\config\\out\\default" mkdir "%OSGEO4W_ROOT%\\apps\\$P\\config\\out\\default"

textreplace -std ^
        -t "%OSGEO4W_ROOT%/apps/$P/venv/pyvenv.cfg"

net stop "$SERVICENAME"

reg add "HKLM\\SYSTEM\\CurrentControlSet\\Services\\${SERVICENAME// /}" ^
	/f ^
	/v Environment ^
	/t REG_MULTI_SZ ^
	/d "PATH=%OSGEO4W_ROOT%\\apps\\%QGIS_PKG%\\bin;%PATH%\\0PYTHONHOME=%OSGEO4W_ROOT%\\apps\\$PYTHON\0"

copy "%OSGEO4W_ROOT%\\bin\\libcrypto-1_1-x64.dll" "%OSGEO4W_ROOT%\\apps\\$PYTHON\\DLLs"
copy "%OSGEO4W_ROOT%\\bin\\libssl-1_1-x64.dll" "%OSGEO4W_ROOT%\\apps\\$PYTHON\\DLLs"

net start "$SERVICENAME"

REM curl -X POST "http://127.0.0.1/config/generate_configs?tenant=default"

endlocal
EOF

cat <<EOF >preremove.bat
del "%OSGEO4W_ROOT%\\httpd.d\\httpd_$P.conf"
if exist "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis.conf.off-$P" ren "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis.conf.off-$P" httpd_qgis.conf
if exist "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis-ltr.conf.off-$P" ren "%OSGEO4W_ROOT%\\httpd.d\\httpd_qgis-ltr.conf.off-$P" httpd_qgis-ltr.conf
reg delete "HKLM\\SYSTEM\\CurrentControlSet\\Services\\${SERVICENAME// /}" /v Environment /f
EOF

cat <<EOF >httpd.conf.tmpl
LoadModule headers_module modules/mod_headers.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule fcgid_module modules/mod_fcgid.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule wsgi_module "@o4wroot@/apps/$PYTHON/lib/site-packages/mod_wsgi/server/mod_wsgi.cp${PYTHON#Python}-win_amd64.pyd"

LoadModule ssl_module modules/mod_ssl.so

Define PKG @qgispkg@
Define QWCS_DIR "@o4wroot@/apps/$P"

ServerName localhost
ServerAdmin webmaster@localhost

# SetEnv FLASK-DEBUG		1
SetEnv AUTH_REQUIRED		1
SetEnv PYTHONIOENCODING		utf-8
SetEnv PGCLIENTENCODING		utf-8
SetEnv PGSERVICEFILE		\${QWCS_DIR}/config/pg_service.conf
SetEnv JWT_SECRET_KEY		"@securekey@"
SetEnv QWC_CONFIG_PATH		\${QWCS_DIR}/config/
SetEnv INPUT_CONFIG_PATH	\${QWCS_DIR}/config/in/
SetEnv OUTPUT_CONFIG_PATH	\${QWCS_DIR}/config/out/
SetEnv CONFIG_PATH		\${QWCS_DIR}/config/out/

SetEnv GROUP_REGISTRATION_ENABLED False

# Header always set Referrer-Policy no-referrer

RewriteEngine on
RewriteRule ^/cgi-bin/.*$ - [F]

WSGIPythonHome "\${QWCS_DIR}/venv"
WSGIPassAuthorization On

WSGIScriptAlias /api/data	\${QWCS_DIR}/qwc-data-service/server.wsgi
#WSGIScriptAlias /api/legend	\${QWCS_DIR}/qwc-legend-service/server.wsgi
WSGIScriptAlias /api/permalink	\${QWCS_DIR}/qwc-permalink-service/server.wsgi
WSGIScriptAlias /api/print	\${QWCS_DIR}/qwc-print-service/server.wsgi
WSGIScriptAlias /config		\${QWCS_DIR}/qwc-config-generator/server.wsgi
WSGIScriptAlias /auth		\${QWCS_DIR}/qwc-db-auth/server.wsgi
#WSGIScriptAlias /auth		\${QWCS_DIR}/qwc-ldap-auth/server.wsgi
WSGIScriptAlias /wms		\${QWCS_DIR}/qwc-ogc-service/server.wsgi
WSGIScriptAlias /qwc-admin	\${QWCS_DIR}/qwc-admin-gui/server.wsgi
WSGIScriptAlias /qwc2		\${QWCS_DIR}/qwc-map-viewer/server.wsgi

<Directory "\${QWCS_DIR}">
	Options -Indexes +FollowSymLinks -MultiViews
	Require all granted
</Directory>

<Location "/config">
	Require local
</Location>

<FilesMatch "\.json$">
	Header set Content-Type "application/json"
</FilesMatch>

<FilesMatch "^data\.\w\w-\w\w$">
	Header set Content-Type "application/json"
</FilesMatch>

FcgidMaxProcesses 4

Listen 127.0.0.1:8001
<VirtualHost 127.0.0.1:8001>
	ServerName localhost
	ServerAdmin webmaster@localhost

	DocumentRoot @o4wroot@/apps/apache/htdocs

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# LogLevel info

	ErrorLog "\${SRVROOT}/logs/qgisserver-error.log"
	CustomLog "\${SRVROOT}/logs/qgisserver-access.log" combined

	RewriteEngine On
	RewriteRule ^/wms/(.+)$ /cgi-bin/qgis_mapserv.fcgi.exe?map=@o4wroot@/apps/$P/projects/\$1.qgs [QSA,PT]

	ScriptAlias /cgi-bin/qgis_mapserv.fcgi.exe @o4wroot@/apps/\${PKG}/bin/qgis_mapserv.fcgi.exe

	<Directory "@o4wroot@/apps/\${PKG}/bin/">
		SetHandler fcgid-script
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Require all granted
	</Directory>

	Header set Access-Control-Allow-Origin "*"

	FcgidProcessLifeTime 0
	FcgidIdleTimeout 0
	FcgidMaxRequestsPerProcess 0
	FcgidConnectTimeout 20
	FcgidIOTimeout 600

	FcgidInitialEnv PATH "@osgeo4w@\\apps\\\${PKG}%\\bin;@osgeo4w@\\bin;@osgeo4w@\\apps\\qt5\\bin;@WINDIR@\\system32;%WINDIR;%WINDIR%\\system32\\WBem"
	FcgidInitialEnv QT_PLUGIN_PATH @osgeo4w@\\apps\\\${PKG}\\qtplugins;@osgeo4w@\\apps\\qt5\\plugins
	FcgidInitialEnv QGIS_PLUGIN_PATH @o4wroot@/apps/$P/qgis-serverplugins
	FcgidInitialEnv O4W_QT_PREFIX @o4wroot@/apps/Qt5
	FcgidInitialEnv O4W_QT_BINARIES @o4wroot@/apps/Qt5/bin
	FcgidInitialEnv O4W_QT_PLUGINS @o4wroot@/apps/Qt5/plugins
	FcgidInitialEnv O4W_QT_LIBRARIES @o4wroot@/apps/Qt5/lib
	FcgidInitialEnv O4W_QT_TRANSLATIONS @o4wroot@/apps/Qt5/translations
	FcgidInitialEnv O4W_QT_HEADERS @o4wroot@/apps/Qt5/include
	FcgidInitialEnv O4W_QT_DOC @o4wroot@/apps/Qt5/doc
	FcgidInitialEnv O4W_QT_FONTS @o4wroot@/apps/Qt5/fonts
	FcgidInitialEnv GDAL_DATA @o4wroot@/share/gdal
	FcgidInitialEnv PROJ_DATA @o4wroot@/share/proj
	FcgidInitialEnv QGIS_PREFIX_PATH @o4wroot@/apps/\${PKG}
	FcgidInitialEnv TEMP @temp@
	FcgidInitialEnv USERPROFILE @userprofile@
	FcgidInitialEnv PYTHONHOME @osgeo4w@\\apps\\$PYTHON
	FcgidInitialEnv PYTHONPATH @osgeo4w@\\apps\\$PYTHON;@osgeo4w@\\apps\\$PYTHON\\Scripts
	FcgidInitialEnv PYTHONIOENCODING UTF-8
	FcgidInitialEnv QGIS_DEBUG 4
	FcgidInitialEnv QGIS_SERVER_LOG_FILE \${SRVROOT}/logs/qgisserver.log
	FcgidInitialEnv QGIS_SERVER_LOG_LEVEL 0
	FcgidInitialEnv MAX_CACHE_LAYERS 500
	FcgidInitialEnv DISPLAY 0

</VirtualHost>
EOF

cat <<EOF >pg_service.conf
[qwc_configdb]
host=localhost
dbname=qwc_config
user=qwc_admin
password=qwc
sslmode=disable
EOF

cat <<EOF >config.json
{
  "proxyServiceUrl": "",
  "permalinkServiceUrl": "/api/permalink",
  "authServiceUrl": "/auth/",
  "elevationServiceUrl": "",
  "mapInfoService":  "",
  "featureReportService": "",
  "translationsPath": "/qwc2/translations",
  "assetsPath": "/qwc2/assets",
  "urlPositionFormat": "centerAndZoom",
  "urlPositionCrs": "",
  "omitUrlParameterUpdates": false,
  "preserveExtentOnThemeSwitch": true,
  "preserveBackgroundOnThemeSwitch": true,
  "preserveNonThemeLayersOnThemeSwitch": true,
  "allowReorderingLayers": true,
  "preventSplittingGroupsWhenReordering": true,
  "allowLayerTreeSeparators": false,
  "allowRemovingThemeLayers": true,
  "globallyDisableDockableDialogs": false,
  "searchThemes": true,
  "allowAddingOtherThemes": true,
  "allowFractionalZoom": false,
  "localeAwareNumbers": false,
  "identifyTool": "Identify",
  "wmsDpi": 96,
  "wmsHidpi": true,
  "externalLayerFeatureInfoFormats": ["text/html"],
  "defaultFeatureStyle": {
    "strokeColor": [0, 0, 255, 1],
    "strokeWidth": 1,
    "strokeDash": [4],
    "fillColor": [255, 0, 255, 0.33],
    "circleRadius": 10,
    "textOverflow" : true,
    "textFill": "black",
    "textStroke": "white",
    "textFont": "11pt sans-serif"
  },
  "importLayerUrlPresets": [],
  "projections": [
    {
      "code": "EPSG:4647",
      "proj": "+proj=tmerc +lat_0=0 +lon_0=9 +k=0.9996 +x_0=32500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs <>",
      "label": "ETRS89 / UTM N32",
      "extent": [27314176.5984, 2792539.46025, 37685823.8105, 9150159.19061]
    },
    {
      "code": "EPSG:25832",
      "proj": "+proj=tmerc +lat_0=0 +lon_0=9 +k=0.9996 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs <>",
      "label": "ETRS89 / UTM 32N",
      "extent": [-3803165, 2544188, 3710899, 8805908]
    },
    {
      "code": "EPSG:25833",
      "proj": "+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9996 +x_0=500000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs <>",
      "label": "ETRS89 / UTM 33N",
      "extent": [-4685824, 2567241, 4894452, 9150159]
    },
    {
      "code": "EPSG:31466",
      "proj": "+proj=tmerc +lat_0=0 +lon_0=6 +k=1 +x_0=2500000 +y_0=0 +ellps=bessel +towgs84=598.1,73.7,418.2,0.202,0.045,-2.455,6.7 +units=m +no_defs",
      "label": "DHDN / Gauß-Krüger Zone 2",
      "extent": [2198674.97164, 5156935.03086, 3304138.59087, 6172478.95319]
    },
    {
      "code": "EPSG:31467",
      "proj": "+proj=tmerc +lat_0=0 +lon_0=9 +k=1 +x_0=3500000 +y_0=0 +ellps=bessel +towgs84=598.1,73.7,418.2,0.202,0.045,-2.455,6.7 +units=m +no_defs",
      "label": "DHDN / Gauß-Krüger Zone 3",
      "extent": [2968406.76329, 5172797.1438, 4113580.06377, 6141807.67656]
    },
    {
      "code": "EPSG:31468",
      "proj": "+proj=tmerc +lat_0=0 +lon_0=12 +k=1 +x_0=4500000 +y_0=0 +ellps=bessel +towgs84=598.1,73.7,418.2,0.202,0.045,-2.455,6.7 +units=m +no_defs",
      "label": "DHDN / Gauß-Krüger Zone 4",
      "extent": [3738224.07893, 5197527.23054, 4922420.07541, 6119480.25774]
    }
  ],
  "plugins": {
      "mobile": [
        {
          "name": "Map",
          "cfg": {
            "mapOptions": {
              "zoomDuration": 250,
              "antialiasing": true
            },
            "toolsOptions": {
              "OverviewSupport": {
                "tipLabel": "Übersicht"
              },
              "LocateSupport": {
                "keepCurrentZoomLevel": true,
                "startupMode": "DISABLED"
              },
              "ScaleBarSupport": {
                "units": "metric"
              }
            }
          }
        },
        {
          "name": "HomeButton",
          "cfg": {
            "position": 1
          }
        },
        {
          "name": "BackgroundSwitcher",
          "cfg": {
            "position": 0
          }
        },
        {
            "name": "TopBar",
            "cfg": {
              "menuItems": [
                {"key": "ThemeSwitcher", "icon": "themes"},
                {"key": "LayerTree", "icon": "layers"},
                {"key": "Share", "icon": "share"},
                {"key": "Bookmark", "icon": "bookmark"},
                {"key": "Tools", "icon": "tools", "subitems": [
                  {"key": "Identify", "icon": "identify_region", "mode": "Region"},
                  {"key": "Measure", "icon": "measure"},
                  {"key": "Redlining", "icon": "draw"},
                  {"key": "DxfExport", "icon": "dxfexport"},
                  {"key": "RasterExport", "icon": "rasterexport"}
                ]},
                {"key": "Print", "icon": "print"},
                {"key": "Login", "icon": "login"}
              ],
              "searchOptions": {
                "minScaleDenom": 1000,
                "showProviderSelection": true,
                "providerSelectionAllowAll": true,
                "zoomToLayers": true,
                "showProvidersInPlaceholder": true
              },
              "appMenuClearsTask": true,
              "appMenuVisibleOnStartup": false,
              "logoClickResetsTheme": true
            }
        },
        {
          "name": "ThemeSwitcher",
          "cfg": {
            "showLayerAfterChangeTheme": true,
            "collapsibleGroups": true
          }
        },
        {
          "name": "Measure",
          "cfg": {
            "showMeasureModeSwitcher": true
          }
        },
        {
          "name": "BottomBar",
          "cfg": {
            "displayCoordinates": false,
            "displayScales": false,
            "viewertitleUrl": "",
            "termsUrl":  ""
          }
        },
        {
          "name": "Identify",
          "cfg": {
            "params": {
              "FI_POINT_TOLERANCE": 32,
              "FI_LINE_TOLERANCE": 16,
              "FI_POLYGON_TOLERANCE": 8,
              "feature_count": 20
            },
            "enableExport": true,
            "longAttributesDisplay": "wrap",
            "displayResultTree": false,
            "featureInfoReturnsLayerName": true
          }
        },
        {
          "name": "Share",
          "cfg": {
            "showSocials": true,
            "showLink": true,
            "showQRCode": true
          },
          "mapClickAction": "identify"
        },
        {
          "name": "Print",
          "cfg": {
            "printExternalLayers": true,
            "inlinePrintOutput": false,
            "scaleFactor": 1,
            "gridInitiallyEnabled": false
          }
        },
        {
          "name": "Help",
          "mapClickAction": "identify"
        },
        {
          "name": "MapCopyright"
        },
        {
          "name": "LayerTree",
          "cfg": {
            "showLegendIcons": true,
            "showRootEntry": false,
            "showQueryableIcon": true,
            "allowMapTips": true,
            "allowCompare": true,
            "allowImport": true,
            "groupTogglesSublayers": true,
            "grayUnchecked": true,
            "flattenGroups": false,
            "layerInfoWindowSize": {"width": 480, "height": 400},
            "bboxDependentLegend": false
          },
          "mapClickAction": "unset"
        },
        {
          "name": "DxfExport"
        },
        {
          "name": "RasterExport",
          "cfg": {
            "dpis": [96, 300]
          }
        },
        {
          "name": "Redlining"
        },
        {
          "name": "Editing"
        },
        {
          "name": "MapCompare"
        },
        {
          "name": "HeightProfile",
          "cfg": {
            "heighProfilePrecision": 0
          }
        },
        {
          "name": "MapInfoTooltip",
          "cfg": {
            "elevationPrecision": 0,
            "includeWGS84": true
          }
        },
        {
          "name": "Authentication"
        },
        {
          "name": "StartupMarker",
          "cfg": {
            "removeMode": "onclickonmarker"
          }
        },
        {
          "name": "Bookmark"
        }
      ],
      "desktop": [
        {
          "name": "Map",
          "cfg": {
            "showLoading": true,
            "mapOptions": {
              "zoomDuration": 250,
              "antialiasing": true
            },
            "toolsOptions": {
              "OverviewSupport": {
                "tipLabel": "Übersicht"
              },
              "LocateSupport": {
                "keepCurrentZoomLevel": true,
                "stopFollowingOnDrag": true,
                "startupMode": "DISABLED"
              },
              "ScaleBarSupport": {
                "units": "metric"
              }
            },
            "swipeGeometryTypeBlacklist": ["Point"],
            "swipeLayerNameBlacklist": ["*_noswipe"]
          }
        },
        {
          "name": "HomeButton",
          "cfg": {
            "position": 3
          }
        },
        {
          "name": "ZoomIn",
          "cfg": {
            "position": 2
          }
        },
        {
          "name": "ZoomOut",
          "cfg": {
            "position": 1
          }
        },
        {
          "name": "BackgroundSwitcher",
          "cfg": {
            "position": 0
          }
        },
        {
            "name": "TopBar",
            "cfg": {
              "menuItems": [
                {"key": "ThemeSwitcher", "icon": "themes"},
                {"key": "LayerTree", "icon": "layers"},
                {"key": "Share", "icon": "share"},
                {"key": "Bookmark", "icon": "bookmark"},
                {"key": "Tools", "icon": "tools", "subitems": [
                  {"key": "Identify", "icon": "identify_region", "mode": "Region"},
                  {"key": "Measure", "icon": "measure"},
                  {"key": "Redlining", "icon": "draw"},
                  {"key": "DxfExport", "icon": "dxfexport"},
                  {"key": "RasterExport", "icon": "rasterexport"}
                ]},
                {"key": "Print", "icon": "print"},
                {"key": "Login", "icon": "login"}
              ],
              "toolbarItems": [
                {"key": "Measure", "mode": "LineString", "icon": "measure_line"},
                {"key": "Redlining", "icon": "draw"},
                {"key": "Print", "icon": "print"},
                {"key": "LayerTree", "icon": "layers"}
              ],
              "searchOptions": {
                "minScaleDenom": 1000,
                "showProviderSelection": true,
                "providerSelectionAllowAll": true,
                "zoomToLayers": true,
                "showProvidersInPlaceholder": true
              },
              "appMenuClearsTask": true,
              "appMenuVisibleOnStartup": false,
              "logoSrc": "/qwc2/assets/img/logo.svg",
              "logoUrl": "/qwc2"
            }
        },
        {
          "name": "BottomBar",
          "cfg": {
            "viewertitleUrl": "",
            "termsUrl":  ""
          }
        },
        {
          "name": "Measure",
          "cfg": {
            "showMeasureModeSwitcher": true
          }
        },
        {
          "name": "ThemeSwitcher",
          "cfg": {
            "showLayerAfterChangeTheme": true,
            "collapsibleGroups": true
          }
        },
        {
          "name": "LayerTree",
          "cfg": {
            "width": "27.5em",
            "showLegendIcons": true,
            "showRootEntry": false,
            "showQueryableIcon": true,
            "allowMapTips": true,
            "allowCompare": true,
            "allowImport": true,
            "groupTogglesSublayers": true,
            "grayUnchecked": true,
            "flattenGroups": false,
            "layerInfoWindowSize": {"width": 480, "height": 400},
            "bboxDependentLegend": false,
            "showToggleAllLayersCheckbox": true
          },
          "mapClickAction": "identify"
        },
        {
          "name": "Identify",
          "cfg": {
            "params": {
              "FI_POINT_TOLERANCE": 16,
              "FI_LINE_TOLERANCE": 8,
              "FI_POLYGON_TOLERANCE": 4,
              "feature_count": 20,
              "region_feature_count": 100
            },
            "enableExport": false,
            "longAttributesDisplay": "wrap",
            "displayResultTree": false,
            "featureInfoReturnsLayerName": true,
            "initialWidth": 480,
            "initialHeight": 550
          }
        },
        {
          "name": "MapTip"
        },
        {
          "name": "Share",
          "cfg": {
            "showSocials": false,
            "showLink": true,
            "showQRCode": true
          },
          "mapClickAction": "identify"
        },
        {
          "name": "Print",
          "cfg": {
            "printExternalLayers": true,
            "inlinePrintOutput": false,
            "scaleFactor": 1,
            "gridInitiallyEnabled": false
          }
        },
        {
          "name": "Help",
          "mapClickAction": "identify"
        },
        {
          "name": "MapCopyright"
        },
        {
          "name": "DxfExport",
          "cfg": {
            "formatOptions": "MODE:SYMBOLLAYERSYMBOLOGY;"
          }
        },
        {
          "name": "RasterExport",
          "cfg": {
            "dpis": [96, 300]
          }
        },
        {
          "name": "Redlining"
        },
        {
          "name": "Editing"
        },
        {
          "name": "MapCompare"
        },
        {
          "name": "HeightProfile",
          "cfg": {
            "heighProfilePrecision": 0
          }
        },
        {
          "name": "MapInfoTooltip",
          "cfg": {
            "elevationPrecision": 0,
            "includeWGS84": true
          }
        },
        {
          "name": "Authentication",
          "cfg": {
            "idleTimeout": 3600
          }
        },
        {
          "name": "LoginUser"
        },
        {
          "name": "StartupMarker",
          "cfg": {
            "removeMode": "onclickonmarker"
          }
        },
        {
          "name": "API"
        },
        {
          "name": "ScratchDrawing"
        },
        {
          "name": "LoginUser"
        },
        {
          "name": "Bookmark"
        }
      ]
  }
}
EOF

cat <<EOF >tenantConfig.json.tmpl
{
  "\$schema": "https://github.com/qwc-services/qwc-config-generator/raw/master/schemas/qwc-config-generator.json",
  "service": "config-generator",
  "config": {
    "tenant": "default",
    "validate_schema": false,
    "default_qgis_server_url": "http://localhost:8001/wms/",
    "config_db_url": "postgresql:///?service=qwc_configdb",
    "permissions_default_allow": true,
    "qgis_projects_base_dir": "@o4wroot@/apps/$P/projects/",
    "qgis_projects_scan_base_dir": "@o4wroot@/apps/$P/projects/",
    "#skip_print_layer_groups": true
  },
  "themesConfig": {
    "defaultScales": [
      1000000,
      500000,
      250000,
      100000,
      50000,
      25000,
      10000,
      7500,
      5000,
      2500,
      1000,
      500,
      250,
      100,
      50
    ],
    "defaultPrintGrid": [
      {
        "s": 10000000,
        "x": 1000000,
        "y": 1000000
      },
      {
        "s": 1000000,
        "x": 100000,
        "y": 100000
      },
      {
        "s": 100000,
        "x": 10000,
        "y": 10000
      },
      {
        "s": 10000,
        "x": 1000,
        "y": 1000
      },
      {
        "s": 1000,
        "x": 100,
        "y": 100
      },
      {
        "s": 100,
        "x": 10,
        "y": 10
      }
    ],
    "defaultWMSVersion": "1.3.0",
    "defaultBackgroundLayers": [],
    "defaultSearchProviders": [
      "coordinates"
    ],
    "defaultMapCrs": "EPSG:25832",
    "themes": {
      "items": [
        {
          "url": "/wms/default",
          "title": "default",
          "thumbnail": "default.jpg",
          "attribution": "",
          "attributionUrl": "",
          "default": true,
          "mapCrs": "EPSG:25832",
          "additionalMouseCrs": [
            "EPSG:4647"
          ],
          "scales": [
            500000,
            250000,
            100000,
            75000,
            50000,
            25000,
            10000,
            5000,
            2500,
            1000,
            500,
            250,
            100,
            50
          ],
          "printScales": [
            200000,
            100000,
            75000,
            50000,
            25000,
            10000,
            7500,
            5000,
            2500,
            2000,
            1500,
            1000,
            750,
            500,
            250,
            100
          ],
          "printResolutions": [
            150,
            300,
            600
          ],
          "skipEmptyFeatureAttributes": true,
          "collapseLayerGroupsBelowLevel": 1,
          "searchProviders": [
            "coordinates",
            {
              "key": "layers",
              "label": "Ebene",
              "theme": "default",
              "priority": 1
            }
          ],
          "externalLayers": [],
          "backgroundLayers": [
            {
              "name": "mapnik",
              "printLayer": "",
              "visibility": true
            },
            {
              "name": "web",
              "printLayer": "",
              "visibility": false
            }
          ]
        }
      ],
      "backgroundLayers": [
        {
          "type": "osm",
          "name": "mapnik",
          "title": "Open Street Map",
          "group": "web",
          "source": "osm",
          "thumbnail": "img/mapthumbs/mapnik.jpg",
          "attribution": "OpenStreetMap contributors",
          "attributionUrl": "https://www.openstreetmap.org/copyright"
        },
        {
          "type": "tileprovider",
          "provider": "OpenTopoMap",
          "title": "OpenTopoMap",
          "group": "web",
          "name": "opentopomap",
          "tiled": true,
          "thumbnail": "img/mapthumbs/opentopomap.jpg",
          "attribution": "Kartendaten: \u00a9 <a href=\"https://openstreetmap.org/copyright\">OpenStreetMap</a> Mitwirkende, SRTM | Kartendarstellung: \u00a9 <a href=\"http://opentopomap.org\">OpenTopoMap</a> (<a href=\"https://creativecommons.org/licenses/by-sa/3.0/\">CC-BY-SA</a>)"
        },
        {
          "type": "wmts",
          "url": "https://sgx.geodatenzentrum.de/wmts_topplus_open/tile/1.0.0/web/default/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png",
          "name": "web",
          "title": "TopPlusOpen",
          "group": "web",
          "attribution": "&copy; <a href=\"https://www.bkg.bund.de\" target=\"_blank\">Bundesamt f\u00fcr Kartographie und Geod\u00e4sie</a> 2021, <a href=\"https://sg.geodatenzentrum.de/web_public/Datenquellen_TopPlus_Open.pdf\" target=\"_blank\">Datenquellen</a>",
          "thumbnail": "img/mapthumbs/topplusopen.jpg",
          "tileMatrixPrefix": "",
          "tileMatrixSet": "EU_EPSG_25832_TOPPLUS",
          "projection": "EPSG:25832",
          "originX": -3803165.98427,
          "originY": 8805908.08285,
          "resolutions": [
            4891.969810252,
            2445.984905126,
            1222.9924525615997,
            611.4962262807999,
            305.74811314039994,
            152.87405657047998,
            76.43702828523999,
            38.21851414248,
            19.109257071295996,
            9.554628535647998,
            4.777314267823999,
            2.3886571339119995,
            1.1943285669559998,
            0.5971642834779999
          ],
          "tileSize": [
            256,
            256
          ]
        },
        {
          "type": "wmts",
          "url": "https://sgx.geodatenzentrum.de/wmts_topplus_open/tile/1.0.0/web_grau/default/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png",
          "name": "web_grau",
          "title": "TopPlusOpen Graustufen",
          "group": "web",
          "attribution": "&copy; <a href=\"https://www.bkg.bund.de\" target=\"_blank\">Bundesamt f\u00fcr Kartographie und Geod\u00e4sie</a> 2021, <a href=\"https://sg.geodatenzentrum.de/web_public/Datenquellen_TopPlus_Open.pdf\" target=\"_blank\">Datenquellen</a>",
          "thumbnail": "img/mapthumbs/topplusopen-grau.jpg",
          "tileMatrixPrefix": "",
          "tileMatrixSet": "EU_EPSG_25832_TOPPLUS",
          "projection": "EPSG:25832",
          "originX": -3803165.98427,
          "originY": 8805908.08285,
          "resolutions": [
            4891.969810252,
            2445.984905126,
            1222.9924525615997,
            611.4962262807999,
            305.74811314039994,
            152.87405657047998,
            76.43702828523999,
            38.21851414248,
            19.109257071295996,
            9.554628535647998,
            4.777314267823999,
            2.3886571339119995,
            1.1943285669559998,
            0.5971642834779999
          ],
          "tileSize": [
            256,
            256
          ]
        }
      ]
    }
  },
  "services": [
    {
      "name": "ogc",
      "generator_config": {
        "wms_services": {
          "online_resources": {
            "service": "/wms/",
            "feature_info": "/wms/",
            "legend": "/wms/"
          }
        }
      },
      "config": {
        "default_qgis_server_url": "http://localhost:8001/wms/"
      }
    },
    {
      "name": "mapViewer",
      "generator_config": {
        "qwc2_config": {
          "qwc2_config_file": "@o4wroot@/apps/$P/config/in/default/config.json",
          "qwc2_index_file": "@o4wroot@/apps/$P/config/in/default/index.html"
        }
      },
      "config": {
        "qwc2_path": "@o4wroot@/apps/qwc2/",
        "auth_service_url": "/auth/",
        "data_service_url": "/api/data/",
        "#document_service_url": "/api/document/",
        "#elevation_service_url": "/elevation/",
        "info_service_url": "/api/featureinfo/",
        "#legend_service_url": "/api/legend/",
        "#mapinfo_service_url": "/api/mapinfo/",
        "ogc_service_url": "/wms/",
        "permalink_service_url": "/api/permalink/",
        "print_service_url": "/api/print/",
        "#search_data_service_url": "/api/data/",
        "#search_service_url": "/api/v2/search/"
      }
    },
    {
      "name": "featureInfo",
      "config": {
        "default_qgis_server_url": "http://localhost:8001/wms/"
      }
    },
    {
      "name": "print",
      "config": {
        "ogc_service_url": "http://localhost:8001/wms/",
        "qgis_server_version": "3.4.15"
      }
    },
    {
      "name": "adminGui",
      "config": {
        "db_url": "postgresql:///?service=qwc_configdb",
        "config_generator_service_url": "http://localhost/config/",
        "totp_enabled": false,
        "user_info_fields": [],
        "proxy_url_whitelist": [],
        "proxy_timeout": 60,
        "qgis_projects_base_dir": "@o4wroot@/apps/$P/projects/",
        "plugins": ["themes"],
        "input_config_path": "@o4wroot@/apps/$P/config/in/",
        "qwc2_path": "@o4wroot@/apps/qwc2/",
        "qgs_resources_path": "@o4wroot@/apps/$P/projects/",
        "ogc_service_url": "/wms/"
      }
    },
    {
      "name": "dbAuth",
      "config": {
        "db_url": "postgresql:///?service=qwc_configdb"
      }
    },
    {
      "name": "permalink",
      "config": {
        "db_url": "postgresql:///?service=qwc_configdb",
        "permalinks_table": "qwc_config.permalinks",
        "user_permalink_table": "qwc_config.user_permalinks"
      }
    },
    {
      "name": "data",
      "config": {}
    }
  ]
}
EOF

cat <<EOF >adminGuiConfig.json.tmpl
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://raw.githubusercontent.com/qwc-services/qwc-admin-gui/master/schemas/qwc-admin-gui.json",
  "title": "QWC Admin GUI",
  "type": "object",
  "properties": {
    "$schema": {
      "title": "JSON Schema",
      "description": "Reference to JSON schema of this config",
      "type": "string",
      "format": "uri",
      "default": "https://raw.githubusercontent.com/qwc-services/qwc-admin-gui/master/schemas/qwc-admin-gui.json"
    },
    "service": {
      "title": "Service name",
      "type": "string",
      "const": "admin-gui"
    },
    "config": {
      "title": "Config options",
      "type": "object",
      "properties": {
        "db_url": {
          "description": "DB connection URL",
          "type": "string"
        },
        "config_generator_service_url": {
          "description": "Config generator URL",
          "type": "string"
        },
        "totp_enabled": {
          "description": "Show TOTP fields for two factor authentication",
          "type": "boolean"
        },
        "user_info_fields": {
          "description": "Additional user fields",
          "type": "array",
          "items": {
            "type": "object"
          }
        },
        "proxy_url_whitelist": {
          "description": "List of RegExes for whitelisted URLs",
          "type": "array",
          "items": {
            "type": "object"
          }
        },
        "proxy_timeout": {
          "description": "Timeout in seconds for proxy requests",
          "type": "integer"
        },
        "plugins": {
          "description": "List of plugins to load",
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "input_config_path": {
          "description": "The path to the input configs. Required for 'themes' plugin.",
          "type": "string"
        },
        "qwc2_path": {
          "description": "The path to QWC2 files. Required for 'themes' and 'alkis' plugins.",
          "type": "string"
        },
        "qgs_resources_path": {
          "description": "The path to the QGIS projects. Required for 'themes' plugin.",
          "type": "string"
        },
        "ogc_service_url": {
          "description": "The OGC service URL.",
          "type": "string"
        }
      },
      "required": [
        "db_url",
        "config_generator_service_url",
        "totp_enabled"
      ]
    }
  },
  "required": [
    "service",
    "config"
  ]
}
EOF

cat <<EOF >index.html
<!doctype html>
<html>
<head>
  <meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,minimal-ui"/>
  <meta name="HandheldFriendly" content="true"/>
  <meta name="apple-mobile-web-app-capable" content="yes"/>
  <title>QGIS Web Client 2</title>
  <link rel="stylesheet" href="assets/css/qwc2.css"/>
  <link rel="apple-touch-icon" href="assets/img/app_icon.png"/>
  <link rel="apple-touch-icon" sizes="72x72" href="assets/img/app_icon_72.png"/>
  <link rel="apple-touch-icon" sizes="114x114" href="assets/img/app_icon_114.png"/>
  <link rel="apple-touch-icon" sizes="144x144" href="assets/img/app_icon_144.png"/>
  <link rel="icon" href="assets/img/favicon.ico"/>
  <style>div#splash {
            position: fixed;
            left: 0;
            right: 0;
            top: 0;
            bottom: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .lds-dual-ring {
            display: inline-block;
            width: 80px;
            height: 80px;
        }
        .lds-dual-ring:after {
            content: " ";
            display: block;
            width: 64px;
            height: 64px;
            margin: 8px;
            border-radius: 50%;
            border: 6px solid #595959;
            border-color: #595959 transparent #595959 transparent;
            animation: lds-dual-ring 1.2s linear infinite;
        }
        @keyframes lds-dual-ring {
            0% {
                transform: rotate(0deg);
            }
            100% {
                transform: rotate(360deg);
            }
        }
  </style>
  <script>
        window.addEventListener("load", function(ev) {
            document.getElementById('splash').style.display = 'none';
        }, false);
  </script>
  <script defer="defer" src="dist/QWC2App.js?7ea734b29c40966c7288"></script>
</head>
<body>
<div id="splash"><div class="lds-dual-ring"></div></div><div id="container"></div>
</body>
</html>
EOF

export R=$OSGEO4W_REP/x86_64/release

mkdir -p $R/$P

cat <<EOF >$R/$P/setup.hint
sdesc: "QWC services"
ldesc: "QWC services"
category: Web
requires: qwc2 apache qgis-ltr-server qgis-ltr mod_fcgid python3-mod-wsgi python3-gdal
EOF

(
	set -e
	fetchenv osgeo4w/bin/o4w_env.bat

	rm -fr venv

	virtualenv venv
	fetchenv venv/Scripts/activate.bat

	export PIP_LOG=$(cygpath -am pip.log)
	savelog $PIP_LOG

	pip3 install --ignore-installed --no-cache-dir \
		Flask-WeasyPrint \
		Flask==2.0.2 \
		Flask-Bootstrap==3.3.7.1 \
		Flask-JWT-Extended==4.3.1 \
		Flask-Login \
		Flask-Mail==0.9.1 \
		Flask-WTF==1.0.0 \
		alembic \
		email_validator==1.0.5 \
		flask-cors==3.0.8 \
		flask-ldap3-login \
		flask-restx==0.5.1 \
		jsonschema==4.0.0 \
		pyotp==2.6.0 \
		python-dotenv==0.19.2 \
		qrcode==7.3.1 \
		$P-core==$V \
		python-i18n==0.3.9 \
		xlsxwriter \
		psycopg2-binary

	# Bad hack to circumvent
	# ImportError: cannot import name 'encodings' from 'psycopg2._psycopg'
	# oddity
	patch -p0 --dry-run <diff
	patch -p0 <diff
)

set -x

VENVS=$(cygpath -asw osgeo4w)
VENV=$(cygpath -aw osgeo4w)

sed \
	-e "s,${VENVS//\\/\\\\},@osgeo4w@,g" \
	-e "s,${VENV//\\/\\\\},@osgeo4w@,g" \
	venv/pyvenv.cfg >venv/pyvenv.cfg.tmpl

PY=$(cygpath -aw venv/Scripts/python.exe)
VENVS=$(cygpath -asw venv)
VENV=$(cygpath -aw venv)

sed \
	-e "s,${VENV//\\/\\\\},@osgeo4w@\\\\apps\\\\$P\\\\venv,g" \
	-e "s,${VENVS//\\/\\\\},@osgeo4w@\\\\apps\\\\$P\\\\venv,g" \
	venv/Scripts/activate.bat >venv/Scripts/activate.bat.tmpl

echo -e "textreplace -std -t apps/$P/venv/Scripts/activate.bat\r" >>postinstall.bat

exetmpl() {
        local i=$1
	local d=apps/$P/$i

        echo -e "textreplace -std -t ${d///\\}\r" >>postinstall.bat
        echo -e "del ${d//\//\\\\}\r" >>preremove.bat

        perl -pe "s#${PY//\\/\\\\}#\@osgeo4w\@\\\\apps\\\\$P\\\\venv\\\\Scripts\\\\python.exe#i" $i >$i.tmpl
        chmod a+rx $i.tmpl
}

for i in venv/Scripts/*.exe; do
	exetmpl "$i"
done

wget -c "https://cdn.jsdelivr.net/npm/proj4@2.6.3/dist/proj4-src.min.js" "https://cdn.jsdelivr.net/gh/openlayers/openlayers.github.io@master/en/v6.4.3/build/ol.js"

tar -cjf $R/$P/$P-$V-$B.tar.bz2 \
	--exclude "*.pyc" \
	--exclude "__pycache__" \
	--exclude ".git*" \
	--exclude ".dockerignore" \
	--exclude "pyvenv.cfg" \
	--exclude "Dockerfile" \
	--exclude "venv/Scripts/*.exe" \
	--exclude "venv/Scripts/activate.bat" \
	--exclude "../$P-core/middleware-test.py" \
	--exclude "../$P-core/README.md" \
	--exclude "../$P-core/LICENSE" \
	--exclude "../$P-core/Makefile" \
	--exclude "../$P-core/setup.py" \
	--exclude "../$P-core/schemas" \
	--exclude "../$P-core/scripts" \
	--xform "s,^$P-core/,apps/$P/," \
	--xform "s,^postinstall.bat,etc/postinstall/$P.bat," \
	--xform "s,^preremove.bat,etc/preremove/$P.bat," \
	--xform "s,^httpd.conf.tmpl,httpd.d/httpd_$P.conf.tmpl," \
	--xform "s,^pg_service.conf,apps/$P/config/pg_service.conf," \
	--xform "s,^config.json,apps/$P/config/in/default/config.json," \
	--xform "s,^tenantConfig.json.tmpl,apps/$P/config/in/default/tenantConfig.json.tmpl," \
	--xform "s,^adminGuiConfig.json.tmpl,apps/$P/config/in/default/adminGuiConfig.json.tmpl," \
	--xform "s,^index.html,apps/$P/config/in/default/index.html," \
	--xform "s,^venv,apps/$P/venv," \
	--xform "s,ol.js,apps/$P/qwc-admin-gui/static/js/ol.js," \
	--xform "s,proj4-src.min.js,apps/$P/qwc-admin-gui/static/js/proj4-src.min.js," \
	../$P-core/* \
	venv \
	postinstall.bat  \
	preremove.bat  \
	httpd.conf.tmpl \
	pg_service.conf \
	config.json \
	tenantConfig.json.tmpl \
	adminGuiConfig.json.tmpl \
	index.html \
	ol.js \
	proj4-src.min.js

tar -cjf $R/$P/$P-$V-$B-src.tar.bz2 \
	-C .. \
	osgeo4w/package.sh \
	osgeo4w/diff \
	osgeo4w/qwc-admin-gui.diff

cp ../$P-core/LICENSE $R/$P/$P-$V-$B.txt

endlog
