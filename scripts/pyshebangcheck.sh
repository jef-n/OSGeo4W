set -o pipefail

while read p; do
	case "$p" in
	"@ python3-"*)
		p=${p#@ }

		while read a; do
			case "$a" in
			"install:"*)
				read _ a _ < <(echo $a)
				while read f; do
					if tar xjOf "$a" "$f" | egrep -q -i -a "[a-z]:[\\/]src"; then
						echo "$p: Script $f with d:/src"
					fi
				done < <(tar tjf $a | grep -i apps/python39/scripts | grep -v "\.tmpl$")
				break
				;;
			esac
		done

		while [ -n "$a" ]; do
			read a
		done
		;;
	esac
done <x86_64/setup.ini
