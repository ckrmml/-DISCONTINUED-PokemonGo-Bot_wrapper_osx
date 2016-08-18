check_ip() {
	curl --socks5-hostname localhost:9048 http://ipecho.net/plain
}

check_port_uniqueness() {
	if [[ ! -f $NODE_DIR/Ports ]] ; then
		touch $NODE_DIR/ports && chmod 755 $NODE_DIR/ports
		echo "$SOCKS_PORT" >>$NODE_DIR/ports
		echo "$CONTROL_PORT" >>$NODE_DIR/ports
		echo "SOCKSPort $SOCKS_PORT" >>$TOR_CFG/torrc.$COUNT_SCND
		echo "ControlPort $CONTROL_PORT" >>$TOR_CFG/torrc.$COUNT_SCND

	else
		log_msg "Checking if Ports are unique..."	
		if [[ "$(cat $NODE_DIR/ports | grep $SOCKS_PORT >/dev/null; printf '%s\n' "$?")" -ne 1 ]] ; then 
			log_fail
			log_failure "Restarting Port generation..."
			socks_port_generation
		else	
			if [[ "$(cat $NODE_DIR/ports | grep $CONTROL_PORT >/dev/null; printf '%s\n' "$?")" -ne 1 ]] ; then 
				log_fail
				log_failure "Restarting Port generation..."
				socks_port_generation
			else
				log_done
				echo "$SOCKS_PORT" >>$NODE_DIR/ports
				echo "$CONTROL_PORT" >>$NODE_DIR/ports
				echo "SOCKSPort $SOCKS_PORT" >>$TOR_CFG/torrc.$COUNT_SCND
				echo "ControlPort $CONTROL_PORT" >>$TOR_CFG/torrc.$COUNT_SCND
			fi
		fi
	fi
}

check_subnet_uniqueness() {
	log_msg "Checking if remote DNS subnet valid..."
	if [ "$REMOTE_SUBNET" -ge 0 -a "$REMOTE_SUBNET" -le 255 ] ; then
		log_done
		if [[ ! -f $NODE_DIR/subnets ]] ; then
			touch $NODE_DIR/subnets
			echo "$REMOTE_SUBNET" >>$NODE_DIR/subnets
		else
			log_msg "Checking if remote DNS subnet is unique..."	
			if [[ "$(cat $NODE_DIR/subnets | grep $REMOTE_SUBNET >/dev/null; printf '%s\n' "$?")" -ne 1 ]] ; then 
				log_fail
				log_failure "Restarting subnet generation..."
				random_subnet_generation
			else	
				log_done
				echo "$REMOTE_SUBNET" >>$NODE_DIR/subnets
			fi
		fi
	else
		log_fail
		log_failure "Restarting subnet generation..."
		random_subnet_generation
	fi
}

choose_country() {
	if [[ ! -z $COUNTRY ]] ; then
	CHOICE=$COUNTRY
	while read line ; do
		COUNTRY_CHOICE=$(grep -i $CHOICE | grep -o '....$' | tail -c +2 | head -c +2)
		NODE_TMP=$COUNTRY_CHOICE.txt
		CC_EXIT_NODES=tmp_nodes_$COUNTRY_CHOICE.txt
		VALID_EXIT_NODES=$NODE_DIR/exit_nodes_$COUNTRY_CHOICE.txt
	done < tools/templates/country_codes.txt
	fi
}

chosen_node() {
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "ExitNodes \$$NODE_CHOICE" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "StrictNodes 1" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "" >>$TOR_CFG/torrc.$COUNT_SCND
	echo "DataDirectory $PWD/$TOR_DATA/$COUNT_SCND" >>$TOR_CFG/torrc.$COUNT_SCND
#	mkdir $TOR_DATA/$COUNT_SCND && chmod 755 $TOR_DATA/$COUNT_SCND
	socks_port_generation
	log_success "Finished writing TOR config file"
}

create_node_list() {
	if [[ -f VALID_EXIT_NODES ]] ; then
		if [[ "$(gdate -d "now - $( gstat -c "%Y" /Volumes/Data/christiankrummel/projects/PokemonGo-Bot_wrapper_osx/tools/tor_nodes/exit_nodes_de.txt  ) seconds" +%s)" -gt 3600 ]] ; then
			LIST_OLD=OLD
		fi
	elif [[ ! -f $VALID_EXIT_NODES ]] ; then
			log_msg "Creating exit node list..."
			curl "https://onionoo.torproject.org/summary?flag=exit" 2>/dev/null >$TMP_DIR/$EXIT_TMP
			curl "https://onionoo.torproject.org/summary?country=$COUNTRY_CHOICE" 2>/dev/null >$TMP_DIR/$NODE_TMP

			awk 'FNR==NR{a[$1];next}($1 in a){print}' "$TMP_DIR/$NODE_TMP" "$TMP_DIR/$EXIT_TMP" >$TMP_DIR/$CC_EXIT_NODES
			awk 'FNR==NR{a[$1];next}($1 in a){print}' "$TMP_DIR/$NODE_TMP" "$TMP_DIR/$EXIT_TMP" | tail -n +4 | ghead -n -4 | cut -d "\"" -f 8 | grep -v '^[\.[:digit:]]*$' >$VALID_EXIT_NODES

			rm -f tmp/$EXIT_TMP
			rm -f tmp/$NODE_TMP
			log_done
	fi
	if [[ $LIST_OLD == OLD ]] ; then
			log_msg "Creating exit node list..."
			rm -f $VALID_EXIT_NODES
			curl "https://onionoo.torproject.org/summary?flag=exit" 2>/dev/null >$TMP_DIR/$EXIT_TMP
			curl "https://onionoo.torproject.org/summary?country=$COUNTRY_CHOICE" 2>/dev/null >$TMP_DIR/$NODE_TMP

			awk 'FNR==NR{a[$1];next}($1 in a){print}' "$TMP_DIR/$NODE_TMP" "$TMP_DIR/$EXIT_TMP" >$TMP_DIR/$CC_EXIT_NODES
			awk 'FNR==NR{a[$1];next}($1 in a){print}' "$TMP_DIR/$NODE_TMP" "$TMP_DIR/$EXIT_TMP" | tail -n +4 | ghead -n -4 | cut -d "\"" -f 8 | grep -v '^[\.[:digit:]]*$' >$VALID_EXIT_NODES

			rm -f tmp/$EXIT_TMP
			rm -f tmp/$NODE_TMP
			log_done

	fi
}

dump_cookie() {
	log_msg "Dumping tor auth cookie..."
	AUTH_COOKIE="$(hexdump -e '32/1 "%02x""\n"' tools/tor_data$COUNT_SCND/control_auth_cookie)"
	log_done
}

inflate_dirs() {
	log_msg "Inflating directories..."
	if [[ ! -d $TMP_DIR ]] ; then
		mkdir $TMP_DIR
	fi

	if [[ ! -d $NODE_DIR ]] ; then
		mkdir $NODE_DIR
	fi

	if [[ ! -d $PROXYCHAINS_CFG ]] ; then
		mkdir $PROXYCHAINS_CFG
	fi
		
	if [[ ! -d $CMD_DIR ]] ; then
		mkdir $CMD_DIR
	fi
	
	if [[ ! -d $TOR_CFG ]] ; then
		mkdir $TOR_CFG
	fi

	if [[ ! -d $TOR_DATA ]] ; then
		mkdir $TOR_DATA
	fi
	
	log_done
}

proxy_bot() {
	clear
	tor_configurator
	proxychains_configurator
}

proxychains_configurator() {
	log_header "Generating proxychains config file"
	random_subnet_generation
	cp -f tools/templates/proxychains.conf.sample $PROXYCHAINS_CFG/pc$COUNT_SCND.conf && chmod 755 $PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	log_msg "Writing proxychains4 config file..."
	echo "proxy_dns" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "remote_dns_subnet $REMOTE_SUBNET" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "[ProxyList]" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	echo "socks4 	127.0.0.1 $SOCKS_PORT" >>$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
	log_done
	log_success "Finished generating proxychains config file"
	PROXY_CONF=$PWD/$PROXYCHAINS_CFG/pc$COUNT_SCND.conf
}

random_subnet_generation() {
	log_msg "Generating random remote DNS subnet..."
	REMOTE_SUBNET=$(head -200 /dev/urandom | cksum | cut -f1 -d " " | fold -w 3 | head -n 1)
	log_done
	check_subnet_uniqueness
}

socks_port_generation() {
	log_msg "Generating random SOCKSPort..."
	SOCKS_PORT=$(head -200 /dev/urandom | cksum | cut -f1 -d " " | fold -w 4 | head -n 1)
	log_done
	
	log_msg "Generating random ControlPort..."
	CONTROL_PORT=$(($SOCKS_PORT+1))
	log_done
	
	check_port_uniqueness
}

tor_command() {
	log_header "Generating TOR command"
	TMP_FILE="$CMD_DIR/\"$COUNT_SCND\"_tor.command"
	log_msg "Copying over routines..."
	echo "mkdir $PWD/PokemonGo-Bot/$TOR_DATA/$COUNT_SCND" >> $TMP_FILE
	echo "tor -f $TOR_CONF" >> $TMP_FILE	
    chmod +x "$TMP_FILE"
    done_or_fail
	log_msg "Executing TOR start command file..."    
    open -b com.apple.terminal "$TMP_FILE"    
    done_or_fail
    log_success "Finished writing TOR command"
    sleep 3
}
	
tor_configurator() {
	local COUNT=0
	while IFS= read -d $'\0' -r file ; do     
 		((COUNT++))
	done < <(find $TOR_CFG -type f -name "torrc.*" -maxdepth 1 -print0) # Avoid a subshell, because we must remember variables

	COUNT_SCND="$COUNT"
	NEW_NAME_COUNT="$((COUNT_SCND++))"

		if [[ $SELF_CHOSEN == y ]] ; then
			clear
			choose_country
			print_msg_newline ""			
			inflate_dirs
			log_header "Generating TOR config file"
			cp -f $TEMPLATE_DIR/torrc.sample $TOR_CFG/torrc.$COUNT_SCND && chmod 755 $TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "ExitNodes {$COUNTRY_CHOICE}" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "StrictNodes 1" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "" >>$TOR_CFG/torrc.$COUNT_SCND
			echo "DataDirectory $PWD/$TOR_DATA/$COUNT_SCND" >>$TOR_CFG/torrc.$COUNT_SCND
			socks_port_generation
			log_success "Finished writing TOR config file"
			TOR_CONF=$PWD/$TOR_CFG/torrc.$COUNT_SCND
			tor_command
		else
			clear
			choose_country
			print_msg_newline ""
			inflate_dirs
			create_node_list
			log_header "Generating TOR config file"
			log_msg "Choosing tor exit node..." 
			head -1 $VALID_EXIT_NODES >$NODE_DIR/chosen_nodes
			tail +2 $VALID_EXIT_NODES >$NODE_DIR/tmp_nodes && mv $NODE_DIR/tmp_nodes $VALID_EXIT_NODES
			cp -f $TEMPLATE_DIR/torrc.sample $TOR_CFG/torrc.$COUNT_SCND && chmod 755 $TOR_CFG/torrc.$COUNT_SCND
			log_done
			while read line ; do
				NODE_CHOICE=$line
			done <$NODE_DIR/chosen_nodes
			chosen_node
			head -1 $NODE_DIR/chosen_nodes >>$NODE_DIR/used_nodes
			TOR_CONF=$PWD/$TOR_CFG/torrc.$COUNT_SCND			
			tor_command
		fi
}

tor_control() {
	telnet localhost CONTROL_PORT
}
