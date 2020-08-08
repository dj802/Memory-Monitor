#!/bin/bash

ram=$(free | awk '/Mem/{printf("%.2f\n"), $3/$2*100}')
limit=60
recipients="DJ.Heavener@cerner.com"
script_schedule=$(awk '/\/some\/dir\/some.sh/{printf "%1s %1s %1s %1s %1s\n", $1, $2, $3, $4, $5}' test3)


incorrect_selection() {
  echo ""
  echo "Incorrect selection! Try again."
  echo ""
}

send_email(){
  SUBJECT="ATTENTION: Memory Utilization is High on $(hostname) at $(date)"
  MESSAGE="/tmp/Mail.out"
  TO="$recipients"
    echo "Node: $(hostname)" >> $MESSAGE
    echo "Date: $(date)" >> $MESSAGE
    echo "Memory Current Usage is: $ram%" >> $MESSAGE
    echo "" >> $MESSAGE
    echo "------------------------------------------------------------------" >> $MESSAGE
    echo "Top Memory Consuming Process Using top command" >> $MESSAGE
    echo "------------------------------------------------------------------" >> $MESSAGE
    echo "$(top -b -o +%MEM | head -n 20)" >> $MESSAGE
    echo "" >> $MESSAGE
    echo "------------------------------------------------------------------" >> $MESSAGE
    echo "Top Memory Consuming Process Using ps command" >> $MESSAGE
    echo "------------------------------------------------------------------" >> $MESSAGE
    echo "$(ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head)" >> $MESSAGE
    mail -s "$SUBJECT" "$TO" < $MESSAGE
  rm /tmp/Mail.out
}

memory_monitor() {

if (( $(echo "$ram > $limit" |bc -l) )); then
  echo Ram usage is $ram above the $limit
  echo "------------------------------------------------------------------"
  echo "Top Memory Consuming Process Using top command"
  echo "------------------------------------------------------------------"
  echo "$(top -b -o +%MEM | head -n 20)"
  echo ""
  echo "------------------------------------------------------------------"
  echo "Top Memory Consuming Process Using ps command"
  echo "------------------------------------------------------------------"
  echo "$(ps -eo pid,ppid,%mem,%cpu,cmd --sort=-%mem | head)"
  send_email
else
  echo $ram is less than $limit
fi
}


set_alert() {
 echo "Default 80%"
 echo "Current alert threshold: $limit%"
 read -p "Memory limit in percent(%): " limit

}

schedule(){
  clear
  until [ "$choice" = "y" ]; do
  clear
  echo "   .-----------------> Minute (0-59)"
  echo " |    .--------------> Hour (0-23)"
  echo " |    |    .-----------> Day of Month (1-31)"
  echo " |    |    |    .--------> Month (1-12) or (jan,feb,mar,apr ...dec)"
  echo " |    |    |    |    .-----> Day of Week (0-6) (Sunday=0 or 7) or (sun,mon,tue,wed,thu,fri,sat)"
  echo " |    |    |    |    |"
  echo " |    |    |    |    |"
  echo " *    *    *    *    *"
  echo "MIN HOUR  DOM  MON  DOW"

  echo ""
  echo "Change Scheudle"
  read -p "Set minute (00-59): " min
  read -p "Set hour (military time ex: 3am=3, 3pm=15): " hr
  read -p "Day of the month (1-31): " dom
  read -p "Month (1-12 or jan,feb,mar,etc): " mon
  read -p "Day of the week (0-6; Sunday=0 or 7): " dow
  echo ""
  echo ""
  echo "Set the run schedule to: "
  echo "$min $hr $dom $mon $dow"
  read -p "Yes or no? (y/n): " choice
  if [ "$choice" == "y" ]; then
  replace=$script_schedule
  script_schedule=$min" "$hr" "$dom" "$mon" "$dow
  sed -i 's/'"$replace"'/'"$scriptschedule"'/' test3
  fi
  echo ""
done
}


email_recipients(){
until [ "num" = "0" ]; do
  echo "List of recipients: " $recipients
  echo "1: Add recipients"
  echo "2: Remove recipient"
  echo "3: Remove all recipients"
  echo "0: Return to main menu"
  read -p "Enter selection: " num
  case $num in
    1) read -p "Email: " new
       recipients=$recipients" "$new;;
    2) read -p "Email to remove: " remove
       recipients=${recipients/$remove};;
    3) read -p "Remove all recipients? (y/n): " yn
       if [ "$yn" == "y" ]; then
         recipients=""
       else
         break
       fi;;
    0) break;;
    *) incorrect_selection  ;;
  esac
done
}


press_enter() {
  echo ""
  echo -n "     Press Enter to continue "
  read
  clear
}


until [ "$selection" = "0" ]; do
  clear
  echo ""
  echo "Node: $(hostname)"
  echo "Ram usage: $ram%"
  echo "Alert Threshold: $limit%"
  echo "Script schedule: $script_schedule"
  echo "Email recipients: $recipients"
  echo ""
  echo "Menu: :"
  echo "---------------------------------------------------------------------"
  echo "        1  -  Run memory monitor now"
  echo "        2  -  Change memory alert threshold(default 80)"
  echo "        3  -  Change run schedule"
  echo "        4  -  Change email recipients"
  echo "        0  -  Exit"
  echo "---------------------------------------------------------------------"
  echo ""
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 )  memory_monitor; press_enter ;;
    2 )  set_alert ; press_enter ;;
    3 )  schedule ; press_enter ;  ;;
    4 )  email_recipients ; press_enter;;
    0 ) clear; exit ;;
    * ) clear ; incorrect_selection ; press_enter ;;
  esac
done
