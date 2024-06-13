#!/bin/bash

installApps()
{
    clear
    OS="$REPLY" ## <-- This $REPLY is about OS Selection
    echo "We can install Docker-CE, Docker-Compose, and Portainer-CE."
    echo "Please select 'y' for each item you would like to install."
    echo "NOTE: Without Docker you cannot use Docker-Compose or Portainer-CE."
    echo ""
    echo ""
    
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    ISCOMP=$( (docker-compose -v ) 2>&1 )

    #### Try to check whether docker is installed and running - don't prompt if it is
    if [[ "$ISACT" != "active" ]]; then
        read -rp "Docker-CE (y/n): " DOCK
    else
        echo "Docker appears to be installed and running."
        echo ""
        echo ""
    fi

    if [[ "$ISCOMP" == *"command not found"* ]]; then
        read -rp "Docker-Compose (y/n): " DCOMP
    else
        echo "Docker-compose appears to be installed."
        echo ""
        echo ""
    fi

    read -rp "Portainer-CE (y/n): " PTAIN

    if [[ "$PTAIN" == [yY] ]]; then
        echo ""
        echo ""
        PS3="Please choose either Portainer-CE or just Portainer Agent: "
        select _ in \
            " Full Portainer-CE (Web GUI for Docker, Swarm, and Kubernetes)" \
            " Portainer Agent - Remote Agent to Connect from Portainer-CE" \
            " Nevermind -- I don't need Portainer after all."
        do
            PORT="$REPLY"
            case $REPLY in
                1) startInstall ;;
                2) startInstall ;;
                3) startInstall ;;
                *) echo "Invalid selection, please try again..." ;;
            esac
        done
    fi
    
    startInstall
}

startInstall() 
{
    clear
    echo "#######################################################"
    echo "###         Preparing for Installation              ###"
    echo "#######################################################"
    echo ""
    sleep 3s

    #######################################################
    ###           Install for Debian / Ubuntu           ###
    #######################################################

    if [[ "$OS" != "1" ]]; then
        echo "    1. Installing System Updates... this may take a while...be patient. If it is being done on a Digial Ocean VPS, you should run updates before running this script."
        (sudo apt update && sudo apt upgrade -y) > ~/docker-script-install.log 2>&1 &
        ## Show a spinner for activity progress
        pid=$! # Process Id of the previous running command
        spin='-\|/'
        i=0
        while kill -0 $pid 2>/dev/null
        do
            i=$(( (i+1) %4 ))
            printf "\r${spin:$i:1}"
            sleep .1
        done
        printf "\r"

        echo "    2. Install Prerequisite Packages..."
        sleep 2s

        sudo apt install curl wget git -y >> ~/docker-script-install.log 2>&1

        echo "    3. Installing Docker-CE (Community Edition)..."
        sleep 2s

        curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1

        echo "      - docker-ce version is now:"
        DOCKERV=$(docker -v)
        echo "          "${DOCKERV}
        sleep 3s

        if [[ "$OS" == 2 ]]; then
            echo "    5. Starting Docker Service"
            sudo systemctl docker start >> ~/docker-script-install.log 2>&1
        fi

    fi
        
    
    #######################################################
    ###              Install for CentOS 7 or 8          ###
    #######################################################
    if [[ "$OS" == "1" ]]; then
        if [[ "$DOCK" == [yY] ]]; then
            echo "    1. Updating System Packages..."
            sudo yum check-update >> ~/docker-script-install.log 2>&1

            echo "    2. Installing Prerequisite Packages..."
            sudo dnf install git curl wget -y >> ~/docker-script-install.log 2>&1

            echo "    3. Installing Docker-CE (Community Edition)..."

            sleep 2s
            (curl -fsSL https://get.docker.com/ | sh) >> ~/docker-script-install.log 2>&1

            echo "    4. Starting the Docker Service..."

            sleep 2s


            sudo systemctl start docker >> ~/docker-script-install.log 2>&1

            echo "    5. Enabling the Docker Service..."
            sleep 2s

            sudo systemctl enable docker >> ~/docker-script-install.log 2>&1

            echo "      - docker version is now:"
            DOCKERV=$(docker -v)
            echo "        "${DOCKERV}
            sleep 3s
        fi
    fi

    #######################################################
    ###               Install for Arch Linux            ###
    #######################################################

    if [[ "$OS" == "5" ]]; then
        read -rp "Do you want to install system updates prior to installing Docker-CE? (y/n): " UPDARCH
        if [[ "UPDARCH" == [yY] ]]; then
            echo "    1. Installing System Updates... this may take a while...be patient."
            (sudo pacman -Syu) > ~/docker-script-install.log 2>&1 &
            ## Show a spinner for activity progress
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"
        else
            echo "    1. Skipping system update..."
            sleep 2s
        fi

        echo "    2. Installing Prerequisit Packages..."
        sudo pacman -Sy git curl wget >> ~/docker-script-install.log 2>&1

        echo "    3. Installing Docker-CE (Community Edition)..."
            sleep 2s

            curl -fsSL https://get.docker.com | sh >> ~/docker-script-install.log 2>&1

            echo "    - docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo "        "${DOCKERV}
            sleep 3s
    fi

    if [[ "$DOCK" == [yY] ]]; then
        # add current user to docker group so sudo isn't needed
        echo ""
        echo "  - Attempting to add the currently logged in user to the docker group..."

        sleep 2s
        sudo usermod -aG docker "${USER}" >> ~/docker-script-install.log 2>&1
        echo "  - You'll need to log out and back in to finalize the addition of your user to the docker group."
        echo ""
        echo ""
        sleep 3s
    fi

    if [[ "$DCOMP" = [yY] ]]; then
        echo "############################################"
        echo "######     Install Docker-Compose     ######"
        echo "############################################"

        # install docker-compose
        echo ""
        echo "    1. Installing Docker-Compose..."
        echo ""
        echo ""
        sleep 2s

        ######################################
        ###     Install Debian / Ubuntu    ###
        ######################################        
        
        if [[ "$OS" == "2" || "$OS" == "3" || "$OS" == "4" ]]; then
            sudo apt install docker-compose -y >> ~/docker-script-install.log 2>&1
        fi

        ######################################
        ###        Install CentOS 7 or 8   ###
        ######################################

        if [[ "$OS" == "1" ]]; then
            sudo curl -L "https://github.com/docker/compose/releases/download/latest/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >> ~/docker-script-install.log 2>&1

            sudo chmod +x /usr/local/bin/docker-compose >> ~/docker-script-install.log 2>&1
        fi

        ######################################
        ###        Install Arch Linux      ###
        ######################################

        if [[ "$OS" == "5" ]]; then
            sudo pacman -Sy >> ~/docker-script-install.log 2>&1
            sudo pacman -Sy docker-compose > ~/docker-script-install.log 2>&1
        fi

        echo ""

        echo "      - Docker Compose Version is now: " 
        DOCKCOMPV=$(docker-compose --version)
        echo "        "${DOCKCOMPV}
        echo ""
        echo ""
        sleep 3s
    fi

    ##########################################
    #### Test if Docker Service is Running ###
    ##########################################
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    if [[ "$ISACt" != "active" ]]; then
        echo "Giving the Docker service time to start..."
        while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
            sudo systemctl
