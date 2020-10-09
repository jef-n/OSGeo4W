/******************************************************************************
 *
 * Project:  OSGeo4W
 * Purpose:  Retrieve special folder
 * Author:   Jürgen E. Fischer <jef@norbit.de>
 *
 ******************************************************************************
 * Copyright (c) 2020, Jürgen E. Fischer, norBIT GmbH
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ****************************************************************************/

#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <knownfolders.h>
#include <shlobj.h>

int wmain(int argc, wchar_t *argv[])
{
  if(argc != 2)
    return 1;

  struct {
    LPWSTR name;
    REFKNOWNFOLDERID id;
  } folders[] = {
    { L"NetworkFolder", &FOLDERID_NetworkFolder },
    { L"ComputerFolder", &FOLDERID_ComputerFolder },
    { L"InternetFolder", &FOLDERID_InternetFolder },
    { L"ControlPanelFolder", &FOLDERID_ControlPanelFolder },
    { L"PrintersFolder", &FOLDERID_PrintersFolder },
    { L"SyncManagerFolder", &FOLDERID_SyncManagerFolder },
    { L"SyncSetupFolder", &FOLDERID_SyncSetupFolder },
    { L"ConflictFolder", &FOLDERID_ConflictFolder },
    { L"SyncResultsFolder", &FOLDERID_SyncResultsFolder },
    { L"RecycleBinFolder", &FOLDERID_RecycleBinFolder },
    { L"ConnectionsFolder", &FOLDERID_ConnectionsFolder },
    { L"Fonts", &FOLDERID_Fonts },
    { L"Desktop", &FOLDERID_Desktop },
    { L"Startup", &FOLDERID_Startup },
    { L"Programs", &FOLDERID_Programs },
    { L"StartMenu", &FOLDERID_StartMenu },
    { L"Recent", &FOLDERID_Recent },
    { L"SendTo", &FOLDERID_SendTo },
    { L"Documents", &FOLDERID_Documents },
    { L"Favorites", &FOLDERID_Favorites },
    { L"NetHood", &FOLDERID_NetHood },
    { L"PrintHood", &FOLDERID_PrintHood },
    { L"Templates", &FOLDERID_Templates },
    { L"CommonStartup", &FOLDERID_CommonStartup },
    { L"CommonPrograms", &FOLDERID_CommonPrograms },
    { L"CommonStartMenu", &FOLDERID_CommonStartMenu },
    { L"PublicDesktop", &FOLDERID_PublicDesktop },
    { L"ProgramData", &FOLDERID_ProgramData },
    { L"CommonTemplates", &FOLDERID_CommonTemplates },
    { L"PublicDocuments", &FOLDERID_PublicDocuments },
    { L"RoamingAppData", &FOLDERID_RoamingAppData },
    { L"LocalAppData", &FOLDERID_LocalAppData },
    { L"LocalAppDataLow", &FOLDERID_LocalAppDataLow },
    { L"InternetCache", &FOLDERID_InternetCache },
    { L"Cookies", &FOLDERID_Cookies },
    { L"History", &FOLDERID_History },
    { L"System", &FOLDERID_System },
    { L"SystemX86", &FOLDERID_SystemX86 },
    { L"Windows", &FOLDERID_Windows },
    { L"Profile", &FOLDERID_Profile },
    { L"Pictures", &FOLDERID_Pictures },
    { L"ProgramFilesX86", &FOLDERID_ProgramFilesX86 },
    { L"ProgramFilesCommonX86", &FOLDERID_ProgramFilesCommonX86 },
    { L"ProgramFilesX64", &FOLDERID_ProgramFilesX64 },
    { L"ProgramFilesCommonX64", &FOLDERID_ProgramFilesCommonX64 },
    { L"ProgramFiles", &FOLDERID_ProgramFiles },
    { L"ProgramFilesCommon", &FOLDERID_ProgramFilesCommon },
    { L"UserProgramFiles", &FOLDERID_UserProgramFiles },
    { L"UserProgramFilesCommon", &FOLDERID_UserProgramFilesCommon },
    { L"AdminTools", &FOLDERID_AdminTools },
    { L"CommonAdminTools", &FOLDERID_CommonAdminTools },
    { L"Music", &FOLDERID_Music },
    { L"Videos", &FOLDERID_Videos },
    { L"Ringtones", &FOLDERID_Ringtones },
    { L"PublicPictures", &FOLDERID_PublicPictures },
    { L"PublicMusic", &FOLDERID_PublicMusic },
    { L"PublicVideos", &FOLDERID_PublicVideos },
    { L"PublicRingtones", &FOLDERID_PublicRingtones },
    { L"ResourceDir", &FOLDERID_ResourceDir },
    { L"LocalizedResourcesDir", &FOLDERID_LocalizedResourcesDir },
    { L"CommonOEMLinks", &FOLDERID_CommonOEMLinks },
    { L"CDBurning", &FOLDERID_CDBurning },
    { L"UserProfiles", &FOLDERID_UserProfiles },
    { L"Playlists", &FOLDERID_Playlists },
    { L"SamplePlaylists", &FOLDERID_SamplePlaylists },
    { L"SampleMusic", &FOLDERID_SampleMusic },
    { L"SamplePictures", &FOLDERID_SamplePictures },
    { L"SampleVideos", &FOLDERID_SampleVideos },
    { L"PhotoAlbums", &FOLDERID_PhotoAlbums },
    { L"Public", &FOLDERID_Public },
    { L"ChangeRemovePrograms", &FOLDERID_ChangeRemovePrograms },
    { L"AppUpdates", &FOLDERID_AppUpdates },
    { L"AddNewPrograms", &FOLDERID_AddNewPrograms },
    { L"Downloads", &FOLDERID_Downloads },
    { L"PublicDownloads", &FOLDERID_PublicDownloads },
    { L"SavedSearches", &FOLDERID_SavedSearches },
    { L"QuickLaunch", &FOLDERID_QuickLaunch },
    { L"Contacts", &FOLDERID_Contacts },
    { L"SidebarParts", &FOLDERID_SidebarParts },
    { L"SidebarDefaultParts", &FOLDERID_SidebarDefaultParts },
    { L"PublicGameTasks", &FOLDERID_PublicGameTasks },
    { L"GameTasks", &FOLDERID_GameTasks },
    { L"SavedGames", &FOLDERID_SavedGames },
    { L"Games", &FOLDERID_Games },
    { L"SEARCH_MAPI", &FOLDERID_SEARCH_MAPI },
    { L"SEARCH_CSC", &FOLDERID_SEARCH_CSC },
    { L"Links", &FOLDERID_Links },
    { L"UsersFiles", &FOLDERID_UsersFiles },
    { L"UsersLibraries", &FOLDERID_UsersLibraries },
    { L"SearchHome", &FOLDERID_SearchHome },
    { L"OriginalImages", &FOLDERID_OriginalImages },
    { L"DocumentsLibrary", &FOLDERID_DocumentsLibrary },
    { L"MusicLibrary", &FOLDERID_MusicLibrary },
    { L"PicturesLibrary", &FOLDERID_PicturesLibrary },
    { L"VideosLibrary", &FOLDERID_VideosLibrary },
    { L"RecordedTVLibrary", &FOLDERID_RecordedTVLibrary },
    { L"HomeGroup", &FOLDERID_HomeGroup },
    { L"HomeGroupCurrentUser", &FOLDERID_HomeGroupCurrentUser },
    { L"DeviceMetadataStore", &FOLDERID_DeviceMetadataStore },
    { L"Libraries", &FOLDERID_Libraries },
    { L"PublicLibraries", &FOLDERID_PublicLibraries },
    { L"UserPinned", &FOLDERID_UserPinned },
    { L"ImplicitAppShortcuts", &FOLDERID_ImplicitAppShortcuts },
    { L"AccountPictures", &FOLDERID_AccountPictures },
    { L"PublicUserTiles", &FOLDERID_PublicUserTiles },
    { L"AppsFolder", &FOLDERID_AppsFolder },
    { L"StartMenuAllPrograms", &FOLDERID_StartMenuAllPrograms },
    { L"CommonStartMenuPlaces", &FOLDERID_CommonStartMenuPlaces },
    { L"ApplicationShortcuts", &FOLDERID_ApplicationShortcuts },
    { L"RoamingTiles", &FOLDERID_RoamingTiles },
    { L"RoamedTileImages", &FOLDERID_RoamedTileImages },
    { L"Screenshots", &FOLDERID_Screenshots },
    { L"CameraRoll", &FOLDERID_CameraRoll },
    { L"SkyDrive", &FOLDERID_SkyDrive },
    { L"OneDrive", &FOLDERID_OneDrive },
    { L"SkyDriveDocuments", &FOLDERID_SkyDriveDocuments },
    { L"SkyDrivePictures", &FOLDERID_SkyDrivePictures },
    { L"SkyDriveMusic", &FOLDERID_SkyDriveMusic },
    { L"SkyDriveCameraRoll", &FOLDERID_SkyDriveCameraRoll },
    { L"SearchHistory", &FOLDERID_SearchHistory },
    { L"SearchTemplates", &FOLDERID_SearchTemplates },
    { L"CameraRollLibrary", &FOLDERID_CameraRollLibrary },
    { L"SavedPictures", &FOLDERID_SavedPictures },
    { L"SavedPicturesLibrary", &FOLDERID_SavedPicturesLibrary },
    { L"RetailDemo", &FOLDERID_RetailDemo },
    { L"Device", &FOLDERID_Device },
    { L"DevelopmentFiles", &FOLDERID_DevelopmentFiles },
    { L"Objects3D", &FOLDERID_Objects3D },
    { L"AppCaptures", &FOLDERID_AppCaptures },
    { L"LocalDocuments", &FOLDERID_LocalDocuments },
    { L"LocalPictures", &FOLDERID_LocalPictures },
    { L"LocalVideos", &FOLDERID_LocalVideos },
    { L"LocalMusic", &FOLDERID_LocalMusic },
    { L"LocalDownloads", &FOLDERID_LocalDownloads },
    { L"RecordedCalls", &FOLDERID_RecordedCalls },
    { L"AllAppMods", &FOLDERID_AllAppMods },
    { L"CurrentAppMods", &FOLDERID_CurrentAppMods },
    { L"AppDataDesktop", &FOLDERID_AppDataDesktop },
    { L"AppDataDocuments", &FOLDERID_AppDataDocuments },
    { L"AppDataFavorites", &FOLDERID_AppDataFavorites },
    { L"AppDataProgramData", &FOLDERID_AppDataProgramData }
  };

  int i;
  for( i = 0; i < sizeof(folders) / sizeof(*folders) && wcscmp(argv[1], folders[i].name) != 0; i++ )
    ;

  if( i == sizeof(folders) / sizeof(*folders) )
  {
    fwprintf(stderr, L"%s: No folder %s found\n", argv[0], argv[1]);
    return 2;
  }

  PWSTR ppszPath = NULL;
  if( FAILED( SHGetKnownFolderPath( folders[i].id, 0, NULL, &ppszPath ) ) )
  {
    fwprintf(stderr, L"%s: Could not retrieve folder for %s\n", argv[0], argv[i]);
    return 3;
  }

  _putws(ppszPath);

  CoTaskMemFree(ppszPath);

  return 0;
}
