#!/bin/zsh

# 현재 재생 중인 음악의 정보를 표시하는 함수
np(){
	init=1
	help='false'
	while :
	do
		# 음악 앱의 볼륨, 셔플, 반복 상태를 가져옴
		vol=$(osascript -e 'tell application "Music" to get sound volume')
		shuffle=$(osascript -e 'tell application "Music" to get shuffle enabled')
		repeat=$(osascript -e 'tell application "Music" to get song repeat')

		# 키 바인딩 정보
		keybindings="
Keybindings:

p                       재생 / 일시 정지
f                       다음 트랙으로 이동
b                       이전 트랙으로 이동
>                       현재 트랙을 빨리 감기 시작
<                       현재 트랙을 되감기 시작
R                       정상 재생 재개
+                       음악 앱 볼륨 5% 증가
-                       음악 앱 볼륨 5% 감소
s                       셔플 전환
r                       곡 반복 전환
q                       np 종료
Q                       np 및 Music.app 종료"

		# 현재 트랙의 재생 시간과 총 길이를 가져옴
		duration=$(osascript -e 'tell application "Music" to get {player position} & {duration} of current track')
		arr=(`echo ${duration}`)
		curr=$(cut -d . -f 1 <<< ${arr[-2]})
		currMin=$(echo $(( curr / 60 )))
		currSec=$(echo $(( curr % 60 )))

		# 분과 초를 두 자리로 포맷
		if [ ${#currMin} = 1 ]; then
			currMin="0$currMin"
		fi
		if [ ${#currSec} = 1 ]; then
			currSec="0$currSec"
		fi

		# 초기화 또는 현재 시간이 2초 미만일 경우
		if (( curr < 2 || init == 1 )); then
			init=0
			name=$(osascript -e 'tell application "Music" to get name of current track')
			name=${name:0:50}
			artist=$(osascript -e 'tell application "Music" to get artist of current track')
			artist=${artist:0:50}
			record=$(osascript -e 'tell application "Music" to get album of current track')
			record=${record:0:50}
			end=$(cut -d . -f 1 <<< ${arr[-1]})
			endMin=$(echo $(( end / 60 )))
			endSec=$(echo $(( end % 60 )))

			# 종료 시간 포맷
			if [ ${#endMin} = 1 ]; then
				endMin="0$endMin"
			fi
			if [ ${#endSec} = 1 ]; then
				endSec="0$endSec"
			fi

			# 앨범 아트를 가져옴
			if [ "$1" != "-t" ]; then
				rm ~/Library/Scripts/tmp*
				osascript ~/Library/Scripts/album-art.applescript
				if [ -f ~/Library/Scripts/tmp.png ]; then
					art=$(clear; viu -b ~/Library/Scripts/tmp.png -w 31 -h 14)
				else
					art=$(clear; viu -b ~/Library/Scripts/tmp.jpg -w 31 -h 14)
				fi
			fi

			# 색상 변수 설정
			cyan=$(echo -e '\e[00;36m')
			magenta=$(echo -e '\033[01;35m')
			nocolor=$(echo -e '\033[0m')
		fi

		# 볼륨 아이콘 설정
		if [ $vol = 0 ]; then
			volIcon=🔇
		else
			volIcon=🔊
		fi
		vol=$(( vol / 12 ))

		# 셔플 아이콘 설정
		if [ $shuffle = 'false' ]; then
			shuffleIcon='➡️ '
		else
			shuffleIcon=🔀
		fi

		# 반복 아이콘 설정
		if [ $repeat = 'off' ]; then
			repeatIcon='↪️ '
		elif [ $repeat = 'one' ]; then
			repeatIcon=🔂
		else
			repeatIcon=🔁
		fi

		# 볼륨 바와 진행 바 설정
		volBars='▁▂▃▄▅▆▇'
		volBG=${volBars:$vol}
		vol=${volBars:0:$vol}
		progressBars='▇▇▇▇▇▇▇▇▇'
		percentRemain=$(( (curr * 100) / end / 10 ))
		progBG=${progressBars:$percentRemain}
		prog=${progressBars:0:$percentRemain}

		# 텍스트 모드 또는 일반 모드에 따라 출력 형식 결정
		if [ "$1" = "-t" ]; then
			clear
			paste <(printf '%s\n' "$name" "$artist - $record" "$shuffleIcon $repeatIcon $(echo $currMin:$currSec ${cyan}${prog}${nocolor}${progBG} $endMin:$endSec)" "$volIcon $(echo "${magenta}$vol${nocolor}$volBG")") 
		else
			paste <(printf %s "$art") <(printf %s "") <(printf %s "") <(printf %s "") <(printf '%s\n' "$name" "$artist - $record" "$shuffleIcon $repeatIcon $(echo $currMin:$currSec ${cyan}${prog}${nocolor}${progBG} $endMin:$endSec)" "$volIcon $(echo "${magenta}$vol${nocolor}$volBG")") 
		fi

		# 도움말 표시 여부 확인
		if [ $help = 'true' ]; then
			printf '%s\n' "$keybindings"
		fi

		# 사용자 입력 대기
		input=$(/bin/bash -c "read -n 1 -t 1 input; echo \$input | xargs")
		if [[ "${input}" == *"s"* ]]; then
			# 셔플 토글
			if $shuffle ; then
				osascript -e 'tell application "Music" to set shuffle enabled to false'
			else
				osascript -e 'tell application "Music" to set shuffle enabled to true'
			fi
		elif [[ "${input}" == *"r"* ]]; then
			# 반복 모드 토글
			if [ $repeat = 'off' ]; then
				osascript -e 'tell application "Music" to set song repeat to all'
			elif [ $repeat = 'all' ]; then
				osascript -e 'tell application "Music" to set song repeat to one'
			else
				osascript -e 'tell application "Music" to set song repeat to off'
			fi
		elif [[ "${input}" == *"+"* ]]; then
			# 볼륨 증가
			osascript -e 'tell application "Music" to set sound volume to sound volume + 5'
		elif [[ "${input}" == *"-"* ]]; then
			# 볼륨 감소
			osascript -e 'tell application "Music" to set sound volume to sound volume - 5'
		elif [[ "${input}" == *">"* ]]; then
			# 현재 트랙 빨리 감기
			osascript -e 'tell application "Music" to fast forward'
		elif [[ "${input}" == *"<"* ]]; then
			# 현재 트랙 되감기
			osascript -e 'tell application "Music" to rewind'
		elif [[ "${input}" == *"R"* ]]; then
			# 재생 재개
			osascript -e 'tell application "Music" to resume'
		elif [[ "${input}" == *"f"* ]]; then
			# 다음 트랙 재생
			osascript -e 'tell app "Music" to play next track'
		elif [[ "${input}" == *"b"* ]]; then
			# 이전 트랙 재생
			osascript -e 'tell app "Music" to back track'
		elif [[ "${input}" == *"p"* ]]; then
			# 재생 / 일시 정지
			osascript -e 'tell app "Music" to playpause'
		elif [[ "${input}" == *"q"* ]]; then
			# np 종료
			clear
			exit
		elif [[ "${input}" == *"Q" ]]; then
			# np 및 Music.app 종료
			killall Music
			clear
			exit
		elif [[ "${input}" == *"?"* ]]; then
			# 도움말 표시 토글
			if [ $help = 'false' ]; then
				help='true'
			else
				help='false'
			fi
		fi
		read -sk 1 -t 0.001
	done
}

# 음악 라이브러리의 곡 목록을 출력하는 함수
list(){
	usage="Usage: list [-grouping] [name]

  -s                    모든 곡 목록을 나열합니다.
  -r                    모든 앨범 목록을 나열합니다.
  -r PATTERN            앨범 PATTERN의 모든 곡 목록을 나열합니다.
  -a                    모든 아티스트 목록을 나열합니다.
  -a PATTERN            아티스트 PATTERN의 모든 곡 목록을 나열합니다.
  -p                    모든 재생 목록을 나열합니다.
  -p PATTERN            재생 목록 PATTERN의 모든 곡 목록을 나열합니다.
  -g                    모든 장르 목록을 나열합니다.
  -g PATTERN            장르 PATTERN의 모든 곡 목록을 나열합니다."

	if [ "$#" -eq 0 ]; then
		printf '%s\n' "$usage";
	else
		if [ $1 = "-p" ]; then
			# 재생 목록 목록 출력
			if [ "$#" -eq 1 ]; then
				shift
				osascript -e 'tell application "Music" to get name of playlists' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			else
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get name of every track of playlist (item 1 of args)' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			fi
		elif [ $1 = "-s" ]; then
			# 모든 곡 목록 출력
			if [ "$#" -eq 1 ]; then
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get name of every track' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			else
				echo $usage
			fi
		elif [ $1 = "-r" ]; then
			# 앨범 목록 출력
			if [ "$#" -eq 1 ]; then
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get album of every track' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			else
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get name of every track whose album is (item 1 of args)' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			fi
		elif [ $1 = "-a" ]; then
			# 아티스트 목록 출력
			if [ "$#" -eq 1 ]; then
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get artist of every track' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			else
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get name of every track whose artist is (item 1 of args)' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			fi
		elif [ $1 = "-g" ]; then
			# 장르 목록 출력
			if [ "$#" -eq 1 ]; then
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get genre of every track' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			else
				shift
				osascript -e 'on run args' -e 'tell application "Music" to get name of every track whose genre is (item 1 of args)' -e 'end' "$*" | tr "," "\n" | sort | awk '!seen[$0]++' | /usr/bin/pr -t -a -3
			fi
		else
			printf '%s\n' "$usage";
		fi
	fi
}

# 음악을 재생하는 함수
play() {
	usage="Usage: play [-grouping] [name]

  -s                    곡을 선택하고 재생합니다.
  -s PATTERN            곡 PATTERN을 재생합니다.
  -r                    앨범을 선택하고 재생합니다.
  -r PATTERN            앨범 PATTERN에서 재생합니다.
  -a                    아티스트를 선택하고 재생합니다.
  -a PATTERN            아티스트 PATTERN에서 재생합니다.
  -p                    재생 목록을 선택하고 재생합니다.
  -p PATTERN            재생 목록 PATTERN에서 재생합니다.
  -g                    장르를 선택하고 재생합니다.
  -g PATTERN            장르 PATTERN에서 재생합니다.
  -l                    전체 라이브러리에서 재생합니다."

	if [ "$#" -eq 0 ]; then
		printf '%s\n' "$usage"
	else
		if [ $1 = "-p" ]; then
			# 재생 목록 선택 및 재생
			if [ "$#" -eq 1 ]; then
				playlist=$(osascript -e 'tell application "Music" to get name of playlists' | tr "," "\n" | fzf)
				set -- ${playlist:1}
			else
				shift
			fi
			osascript -e 'on run argv
				tell application "Music" to play playlist (item 1 of argv)
			end' "$*"
		elif [ $1 = "-s" ]; then
			# 곡 선택 및 재생
			if [ "$#" -eq 1 ]; then
				song=$(osascript -e 'tell application "Music" to get name of every track' | tr "," "\n" | fzf)
				set -- ${song:1}
			else
				shift
			fi
			osascript -e 'on run argv
				tell application "Music" to play track (item 1 of argv)
			end' "$*"
		elif [ $1 = "-r" ]; then
			# 앨범 선택 및 재생
			if [ "$#" -eq 1 ]; then
				record=$(osascript -e 'tell application "Music" to get album of every track' | tr "," "\n" | sort | awk '!seen[$0]++' | fzf)
				set -- ${record:1}
			else
				shift
			fi
			osascript -e 'on run argv' -e 'tell application "Music"' -e 'if (exists playlist "temp_playlist") then' -e 'delete playlist "temp_playlist"' -e 'end if' -e 'set name of (make new playlist) to "temp_playlist"' -e 'set theseTracks to every track of playlist "Library" whose album is (item 1 of argv)' -e 'repeat with thisTrack in theseTracks' -e 'duplicate thisTrack to playlist "temp_playlist"' -e 'end repeat' -e 'play playlist "temp_playlist"' -e 'end tell' -e 'end' "$*"
		elif [ $1 = "-a" ]; then
			# 아티스트 선택 및 재생
			if [ "$#" -eq 1 ]; then
				artist=$(osascript -e 'tell application "Music" to get artist of every track' | tr "," "\n" | sort | awk '!seen[$0]++' | fzf)
				set -- ${artist:1}
			else
				shift
			fi
			osascript -e 'on run argv' -e 'tell application "Music"' -e 'if (exists playlist "temp_playlist") then' -e 'delete playlist "temp_playlist"' -e 'end if' -e 'set name of (make new playlist) to "temp_playlist"' -e 'set theseTracks to every track of playlist "Library" whose artist is (item 1 of argv)' -e 'repeat with thisTrack in theseTracks' -e 'duplicate thisTrack to playlist "temp_playlist"' -e 'end repeat' -e 'play playlist "temp_playlist"' -e 'end tell' -e 'end' "$*"
		elif [ $1 = "-g" ]; then
			# 장르 선택 및 재생
			if [ "$#" -eq 1 ]; then
				genre=$(osascript -e 'tell application "Music" to get genre of every track' | tr "," "\n" | sort | awk '!seen[$0]++' | fzf)
				set -- ${genre:1}
			else
				shift
			fi
			osascript -e 'on run argv' -e 'tell application "Music"' -e 'if (exists playlist "temp_playlist") then' -e 'delete playlist "temp_playlist"' -e 'end if' -e 'set name of (make new playlist) to "temp_playlist"' -e 'set theseTracks to every track of playlist "Library" whose genre is (item 1 of argv)' -e 'repeat with thisTrack in theseTracks' -e 'duplicate thisTrack to playlist "temp_playlist"' -e 'end repeat' -e 'play playlist "temp_playlist"' -e 'end tell' -e 'end' "$*"
		elif [ $1 = "-l" ]; then
			# 전체 라이브러리 재생
			osascript -e 'tell application "Music"' -e 'play playlist "Library"' -e 'end tell'
		else
			printf '%s\n' "$usage";
		fi
	fi
}

# 스크립트 사용법 안내
usage="Usage: am.sh [function] [-grouping] [name]

  list -s               모든 곡 목록을 나열합니다.
  list -r               모든 앨범 목록을 나열합니다.
  list -r PATTERN       앨범 PATTERN의 모든 곡 목록을 나열합니다.
  list -a               모든 아티스트 목록을 나열합니다.
  list -a PATTERN       아티스트 PATTERN의 모든 곡 목록을 나열합니다.
  list -p               모든 재생 목록을 나열합니다.
  list -p PATTERN       재생 목록 PATTERN의 모든 곡 목록을 나열합니다.
  list -g               모든 장르 목록을 나열합니다.
  list -g PATTERN       장르 PATTERN의 모든 곡 목록을 나열합니다.

  play -s               곡을 선택하고 재생합니다.
  play -s PATTERN       곡 PATTERN을 재생합니다.
  play -r               앨범을 선택하고 재생합니다.
  play -r PATTERN       앨범 PATTERN에서 재생합니다.
  play -a               아티스트를 선택하고 재생합니다.
  play -a PATTERN       아티스트 PATTERN에서 재생합니다.
  play -p               재생 목록을 선택하고 재생합니다.
  play -p PATTERN       재생 목록 PATTERN에서 재생합니다.
  play -g               장르를 선택하고 재생합니다.
  play -g PATTERN       장르 PATTERN에서 재생합니다.
  play -l               전체 라이브러리에서 재생합니다.

  np                    "현재 재생 중" TUI 위젯을 엽니다.
                        (Music.app 트랙이 활성 재생 중이거나 일시 정지 상태여야 함)
  np -t                 텍스트 모드로 열기 (앨범 아트 비활성화)

  np 키 바인딩:

  p                     재생 / 일시 정지
  f                     다음 트랙으로 이동
  b                     이전 트랙으로 이동
  >                     현재 트랙을 빨리 감기 시작
  <                     현재 트랙을 되감기 시작
  R                     정상 재생 재개
  +                     음악 앱 볼륨 5% 증가
  -                     음악 앱 볼륨 5% 감소
  s                     셔플 전환
  r                     곡 반복 전환
  q                     np 종료
  Q                     np 및 Music.app 종료
  ?                     도움말 표시 / 숨기기"

# 스크립트 실행
if [ "$#" -eq 0 ]; then
	printf '%s\n' "$usage";
else
	if [ $1 = "np" ]; then
		shift
		np "$@"
	elif [ $1 = "list" ]; then
		shift
		list "$@"
	elif [ $1 = "play" ]; then
		shift
		play "$@"
	else
		printf '%s\n' "$usage";
	fi
fi
