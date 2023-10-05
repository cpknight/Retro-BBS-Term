#!/usr/bin/bash

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Change to the hard-coded directory for this project.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

cd /home/cpknight/Projects/Retro-BBS-Term

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Make a temporary directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

TMP_DIRECTORY="$(mktemp -d /tmp/retroBBSterm.$BASHPID.XXX)"

echo "    Temporary Dir: ${TMP_DIRECTORY}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Determine an available port in the user range.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

THE_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()');
echo "   Available Port: ${THE_PORT}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start tcpser on that port.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

CMD_TCPSER="tcpser/tcpser -v $THE_PORT -s 57600 -I"
#CMD_TCPSER="tcpser/tcpser -v $THE_PORT"
$CMD_TCPSER >/dev/null 2>&1 &
PID_TCPSER=$!  
echo "       PID/tcpser: ${PID_TCPSER}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Come up with a cool name for the pty device
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

PTY_PATH=${TMP_DIRECTORY}/hayes
echo "    Virtual modem: ${PTY_PATH}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start socat
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

CMD_SOCAT="socat pty,raw,echo=0,link=${PTY_PATH} TCP:127.0.0.1:${THE_PORT}"
#CMD_SOCAT="socat -d -d -v pty,rawer,link=${PTY_PATH} TCP:127.0.0.1:${THE_PORT}"
$CMD_SOCAT >${TMP_DIRECTORY}/socat.log 2>&1 &
PID_SOCAT=$!  
echo "        PID/socat: ${PID_SOCAT}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup qodem
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "# Qodem modem configuration file for retroBBSterm! " > ${TMP_DIRECTORY}/modem.cfg
echo "# " >> ${TMP_DIRECTORY}/modem.cfg
echo "name = Hayes Modem " >> ${TMP_DIRECTORY}/modem.cfg
echo "dev_name = ${PTY_PATH} " >> ${TMP_DIRECTORY}/modem.cfg
echo "lock_dir = /var/lock " >> ${TMP_DIRECTORY}/modem.cfg
echo "init_string = " >> ${TMP_DIRECTORY}/modem.cfg
echo "hangup_string = +~+~+~~~~ATH0^M " >> ${TMP_DIRECTORY}/modem.cfg
echo "dial_string = ATDT " >> ${TMP_DIRECTORY}/modem.cfg
echo "host_init_string = ATE1Q0V1M1H0S0=0^M " >> ${TMP_DIRECTORY}/modem.cfg
echo "answer_string = ATA^M " >> ${TMP_DIRECTORY}/modem.cfg
echo "baud = 57600 " >> ${TMP_DIRECTORY}/modem.cfg
echo "data_bits = 8 " >> ${TMP_DIRECTORY}/modem.cfg
echo "parity = none " >> ${TMP_DIRECTORY}/modem.cfg
echo "stop_bits = 1 " >> ${TMP_DIRECTORY}/modem.cfg
echo "xonxoff = false " >> ${TMP_DIRECTORY}/modem.cfg
echo "rtscts = false " >> ${TMP_DIRECTORY}/modem.cfg
echo "lock_dte_baud = true " >> ${TMP_DIRECTORY}/modem.cfg
echo "ignore_dcd = false " >> ${TMP_DIRECTORY}/modem.cfg
echo " " >> ${TMP_DIRECTORY}/modem.cfg

echo "working_dir = ${TMP_DIRECTORY}" >> ${TMP_DIRECTORY}/qodemrc
echo "host_mode_dir = ${TMP_DIRECTORY}" >> ${TMP_DIRECTORY}/qodemrc
echo "download_dir = /home/cpknight/Downloads" >> ${TMP_DIRECTORY}/qodemrc
echo "upload_dir = /home/cpknight/Downloads" >> ${TMP_DIRECTORY}/qodemrc
echo "scripts_dir = ${TMP_DIRECTORY}  " >> ${TMP_DIRECTORY}/qodemrc
echo "scripts_fifo = ${TMP_DIRECTORY}/script.stderr" >> ${TMP_DIRECTORY}/qodemrc
echo "bew_file = ${TMP_DIRECTORY}/batch_upload.txt " >> ${TMP_DIRECTORY}/qodemrc
echo "editor = subl" >> ${TMP_DIRECTORY}/qodemrc
echo "start_in_phonebook = false" >> ${TMP_DIRECTORY}/qodemrc
echo " " >> ${TMP_DIRECTORY}/qodemrc

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# launch qodem in a new, special kitty instance
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

kitty --override font_size=18 \
	--override remember_window_size=no \
	--override initial_window_width=82c \
	--override initial_window_height=26c \
	qodem/bin/qodem --dotqodem-dir ${TMP_DIRECTORY} --config ${TMP_DIRECTORY}/qodemrc --emulation ansi >${TMP_DIRECTORY}/qodem.log 2>&1

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Kill the tcpser and socat processes 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

kill $PID_TCPSER
# kill $PID_SOCAT    # unnecessary as it kills itself after tcpser exit

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Remove the temporary directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

rm -rf ${TMP_DIRECTORY} >/dev/null 2>&1
