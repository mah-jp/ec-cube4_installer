#!/bin/bash

# ansible-player.sh (Ver.20230124)

if [ "${HOSTS_SELECT}" = "" ]; then
	echo "Usage: HOSTS_SELECT=ほげほげ ${0}"
	exit 1
fi
FILE_HOSTS="hosts_${HOSTS_SELECT}.txt"

CMD_ANSIBLE='ansible-playbook'
OPTION_ANSIBLE="-i ./${FILE_HOSTS} --diff --check" # dry-run
OPTION_ANSIBLE_SAMPLE="-i ./${FILE_HOSTS} --diff" # NOT dry-run
DIR_TASKS=./tasks/ # 末尾に「/」付ける
LIST_YML=$(find ${DIR_TASKS} -maxdepth 1 -name '*.ansible.yml' | sort | sed -e "s#//#/#g" | sed -e "s#${DIR_TASKS}##g")
LIST_YML="${LIST_YML} QUIT"

# 選択表示
select YML_SELECTED in ${LIST_YML}
do
	if [ "${YML_SELECTED}" = 'QUIT' ]; then
		exit
	elif [ "${YML_SELECTED:0:5}" = 'sudo_' ]; then
		# 管理者権限が必要な選択肢
		OPTION_ANSIBLE="${OPTION_ANSIBLE} --ask-become-pass"
		OPTION_ANSIBLE_SAMPLE="${OPTION_ANSIBLE_SAMPLE} --ask-become-pass"
	fi
	break
done

# 選択確認
echo "A selected playbook is '${YML_SELECTED}', and an option is '$@'."
read -p 'Do you want to execute(dry-run) this command? (y/N): ' YESNO
case "${YESNO}" in
	[yY]*)
		# コマンド実行
		echo '#' ${CMD_ANSIBLE} ${OPTION_ANSIBLE} ${DIR_TASKS}${YML_SELECTED} $@
		${CMD_ANSIBLE} ${OPTION_ANSIBLE} ${DIR_TASKS}${YML_SELECTED} $@
		;;
	*)
		echo '# The command has not been executed.'
		;;
esac

echo "# ansible-playbook '${YML_SELECTED}' ('--check' = dry-run) done!"
echo "# If it's OK, execute(REAL) command below:"
echo '#' ${CMD_ANSIBLE} ${OPTION_ANSIBLE_SAMPLE} ${DIR_TASKS}${YML_SELECTED} $@
exit
