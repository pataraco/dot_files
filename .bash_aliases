#!bash - ~/.bash_aliases - sourced by ~/.bashrc

# if interactive shell - display message
[ -n "$PS1" ] && echo "sourcing '.bash_aliases'"
# some ansi colorizatioin escape sequences
D2E="\e[K"              # to delete the rest of the chars on a line
BLD="\e[1m"             # bold
ULN="\e[4m"             # underlined
BLK="\e[30m"            # black FG
RED="\e[31m"            # red FG
GRN="\e[32m"            # green FG
YLW="\e[33m"            # yellow FG
BLU="\e[34m"            # blue FG
MAG="\e[35m"            # magenta FG
CYN="\e[36m"            # cyan FG
RBG="\e[41m"            # red BG
GBG="\e[42m"            # green BG
YBG="\e[43m"            # yellow BG
BBG="\e[44m"            # blue BG
MBG="\e[45m"            # magenta BG
CBG="\e[46m"            # cyan BG
NRM="\e[m"              # to make text normal
# turn on `vi` command line editing - oh yeah!
set -o vi
# set xterm defaults
XTERM='xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000'
# set bash prompt command (and bash prompt)
ORIG_PS1=$PS1
export PROMPT_DIRTRIM=3
# # change grep color to light yelow highlighting with black fg
# export GREP_COLOR="5;43;30"
# change grep color to light green fg on black bg
export GREP_COLOR="1;40;32"
# for changing prompt colors
PRED='\[\e[1;31m\]'      # red (bold)
PGRN='\[\e[1;32m\]'      # green (bold)
PYLW='\[\e[1;33m\]'      # yellow (bold)
PBLU='\[\e[1;34m\]'      # blue (bold)
PMAG='\[\e[1;35m\]'      # magenta (bold)
PCYN='\[\e[1;36m\]'      # cyan (bold)
PNRM='\[\e[m\]'          # to make text normal
# some bind settings
bind Space:magic-space
# update change the title bar of the terminal
echo -ne "\033]0;`whoami`@`hostname`\007"
# set up some globals
REPO_DIR=$HOME/repos

# define functions
function _tmux_send_keys_all_panes () {
# send keys to all tmux panes
   for _pane in $(tmux list-panes -F '#P'); do
      tmux send-keys -t ${_pane} "$@" Enter
   done
}

function awssnsep () {
# AWS SNS list platform application endpoints
   local _USAGE="usage: awssnsep APPLICATION [REGION]"
   local _app=$1
   [ -z "$_app" ] && { echo "$_USAGE"; return; }
   local _region=$2
   [ -n "$_region" ] && _region="--region $_region"
   if [ "$_app" == "all" ]; then
      echo "all platform applications found:"
      aws sns list-platform-applications $_region | grep PlatformApplicationArn | awk '{print $2}' | tr -d '"'
      return
   fi
   local _app_arn=$(aws sns list-platform-applications $_region | grep "arn:.*$_app" | awk '{print $2}' | tr -d '"')
   [ -z "$_app_arn" ] && { echo "none found"; return; }
   local _noa=$(echo "$_app_arn" | wc -l)
   if [ $_noa -gt 1 ]; then
      echo "found more than one app, please be more specific:"
      echo "$_app_arn" | grep $_app
      return
   fi
   local _app_eps=$(aws sns list-endpoints-by-platform-application $_region --platform-application-arn $_app_arn)
   local _enabled=$(echo $_app_eps | jq .Endpoints[].Attributes.Enabled | tr -d '"')
   local _token=$(echo $_app_eps | jq .Endpoints[].Attributes.Token | tr -d '"')
   echo "$_app | $_app_arn | $_enabled | $_token"
}

function awsasgcp () {
# suspend/resume ALL AWS AutoScaling processes
# (optional: only for a specified autoscaling group name or those matching a reg-ex)
# defaults to "dry-run" - must use "--no-dry-run" option to perform
   local _USAGE="usage: awsasgcp -r|--resume or -s|--suspend [--region REGION] [--no-dry-run] [AutoScalingGroupName|RegEx]"
   local _AWS_CMD=$(/usr/bin/which aws 2> /dev/null) || { echo "'aws' needed to run this function"; exit 3; }
   local _JQ_CMD=$(/usr/bin/which jq 2> /dev/null) || { echo "'jq' needed to run this function"; exit 3; }
   local _dryrun=dry-run
   local _pc_cmd
   local _region
   while true; do
      case "$1" in
          -r|--resume) _pc_cmd=resume-processes ; shift  ;;
         -s|--suspend) _pc_cmd=suspend-processes; shift  ;;
             --region) _region="--region $2"    ; shift 2;;
         --no-dry-run) _dryrun=running          ; shift  ;;
                    *) break                             ;;
      esac
   done
   [ -z "$_pc_cmd" ] && { echo "$_USAGE"; return; }
   local _asgn_pattern=$*
   #asg_names=$(aws $_region autoscaling describe-auto-scaling-groups | grep AutoScalingGroupName | cut -d'"' -f4 | grep "$_asgn_pattern")
   #asg_names=$($_AWS_CMD $_region autoscaling describe-auto-scaling-groups | grep AutoScalingGroupName | cut -d'"' -f4 | grep "$_asgn_pattern")
   asg_names=$($_AWS_CMD $_region autoscaling describe-auto-scaling-groups | $_JQ_CMD -r .AutoScalingGroups[].AutoScalingGroupName | grep "$_asgn_pattern")
   if [ -n "$asg_names" ]; then
      for asg_name in $asg_names; do
         echo "$_dryrun: $(basename $_AWS_CMD) $_region autoscaling $_pc_cmd --auto-scaling-group-name $asg_name"
         if [ $_dryrun == "running" ]; then
            $_AWS_CMD $_region autoscaling $_pc_cmd --auto-scaling-group-name $asg_name
         fi
      done
   else
      echo "no matching AWS Auto Scaling Group names found"
   fi
}

function awsdami () {
# some 'aws ec2 describe-images' hacks
   local _USAGE="usage: \
awsdami [OPTIONS]
  -a  ARCH      # Architecture (e.g. i386, x86_64)
  -ht HYPE_TYPE # Hypervisor Type (e.g. ovm, xen)
  -i  ID        # Image ID (RegEx)
  -it IMG_TYPE  # Image Type (e.g. machine, kernel, ramdisk)
  -n  NAME      # Image Name (RegEx)
  -o  OWNERS    # Owners (e.g. amazon, aws-marketplace, AWS ID. default: self)
  -p  PROJECT   # Project
  -r  REGION    # Region (default: us-west-2)
  -s  STATE     # State
  -v  VIRT_TYPE # Virtualization Type (e.g. paravirtual, hvm)
  -vs VOL_SIZE  # Volume Size (in GiB)
  -vt VOL_TYPE  # Volume Type (e.g. gp2, io1, st1, sc1, standard)
  +a            # show Architecture
  +cc           # show Charge Code
  +cd           # show Creation Date
  +ht           # show Hypervisor Type
  +it           # show Image Type
  +o            # show Owner ID
  +p            # show Project
  +ps           # show Public Status
  +rn           # show Root Device Name
  +rt           # show Root Device Type
  +v            # show Virtualization Type
  +vs           # show Volume Size
  +vt           # show Volume Type
  -h            # help (show this message)
default display:
  Image Name | Image ID | State"
   local _awsec2dami_cmd="aws ec2 describe-images"
   local _owners="self"
   local _region="us-west-2"
   local _regions="us-west-1 us-west-2 us-east-1 eu-west-1 eu-central-1"
   local _filters=""
   local _queries="Tags[?Key=='Name'].Value|[0],ImageId,State"
   local _more_qs=""
   local _query="Images[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -a) _filters="Name=architecture,Values=*$2* $_filters"                    ; shift 2;;
         -ht) _filters="Name=hypervisor,Values=*$2* $_filters"                      ; shift 2;;
          -i) _filters="Name=image-id,Values=*$2* $_filters"                        ; shift 2;;
         -it) _filters="Name=image-type,Values=*$2* $_filters"                      ; shift 2;;
          -n) _filters="Name=tag:Name,Values=*$2* $_filters"                        ; shift 2;;
          -o) _owners="$2"                                                          ; shift 2;;
          -p) _filters="Name=tag:Project,Values=*$2* $_filters"                     ; shift 2;;
          -s) _filters="Name=state,Values=*$2* $_filters"                           ; shift 2;;
          -v) _filters="Name=virtualization-type,Values=*$2* $_filters"             ; shift 2;;
         -vs) _filters="Name=block-device-mapping.volume-size,Values=*$2* $_filters"; shift 2;;
         -vt) _filters="Name=block-device-mapping.volume-type,Values=*$2* $_filters"; shift 2;;
          -r) _region=$2                                                            ; shift 2;;
          +a) _more_qs="Architecture,$_more_qs"                                     ; shift  ;;
         +cc) _more_qs="Tags[?Key=='ChargeCode'].Value|[0],$_more_qs"               ; shift  ;;
         +cd) _more_qs="CreationDate,$_more_qs"                                     ; shift  ;;
         +ht) _more_qs="Hypervisor,$_more_qs"                                       ; shift  ;;
         +it) _more_qs="ImageType,$_more_qs"                                        ; shift  ;;
          +o) _more_qs="OwnerId,$_more_qs"                                          ; shift  ;;
          +p) _more_qs="Tags[?Key=='Project'].Value|[0],$_more_qs"                  ; shift  ;;
         +ps) _more_qs="Public,$_more_qs"                                           ; shift  ;;
         +rn) _more_qs="RootDeviceName,$_more_qs"                                   ; shift  ;;
         +rt) _more_qs="RootDeviceType,$_more_qs"                                   ; shift  ;;
          +v) _more_qs="VirtualizationType,$_more_qs"                               ; shift  ;;
         +vs) _more_qs="BlockDeviceMappings[0].Ebs.VolumeSize,$_more_qs"            ; shift  ;;
         +vt) _more_qs="BlockDeviceMappings[0].Ebs.VolumeType,$_more_qs"            ; shift  ;;
          -h) echo "$_USAGE"                                                        ; return ;;
           *) echo "$_USAGE"                                                        ; return ;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_regions; do
         $_awsec2dami_cmd --region=$_region --owners $_owners $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeImages' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_awsec2dami_cmd --region=$_region --owners $_owners $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeImages' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsdasg () {
# some 'aws autoscaling describe-auto-scaling-groups' hacks
  local _USAGE="usage: \
awsdasg [OPTIONS]
  -n NAME      # filter results by this Auto Scaling Group Name
  -m MAX       # the maximum number of items to display
  -r REGION    # the Region to query (default: us-west-2)
  +bt          # show Branch Tag
  +cc          # show Charge Code
  +c           # show Cluster
  +e           # show Env (Environment)
  +ht          # show Health Check Type
  +ii          # show Instance Id(s)
  +ih          # show Instance Health Status
  +lb          # show Load Balancers
  +mr          # show Machine Role
  +p           # show Project
  +v           # show VPC Name
  -h           # help (show this message)
default display:
  ASG name | Launch Config Name | Instances | Desired | Min | Max | Region"
   local _awsasdasg_cmd="aws autoscaling describe-auto-scaling-groups"
   local _max_items=""
   local _region="us-west-2"
   local _regions="us-west-1 us-west-2 us-east-1 eu-west-1 eu-central-1"
   local _reg_exp=""
   local _queries="AutoScalingGroupName,LaunchConfigurationName,length(Instances),DesiredCapacity,MinSize,MaxSize"
   local _more_qs=""
   local _query="AutoScalingGroups[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -n) _reg_exp="$2"                                             ; shift 2;;
          -m) _max_items="--max-items $2"                               ; shift 2;;
          -r) _region=$2                                                ; shift 2;;
         +bt) _more_qs="Tags[?Key=='BranchTag'].Value|[0],$_more_qs"    ; shift  ;;
         +cc) _more_qs="Tags[?Key=='ChargeCode'].Value|[0],$_more_qs"   ; shift  ;;
          +c) _more_qs="Tags[?Key=='Cluster'].Value|[0],$_more_qs"      ; shift  ;;
          +e) _more_qs="Tags[?Key=='Env'].Value|[0],$_more_qs"          ; shift  ;;
         +ht) _more_qs="HealthCheckType,$_more_qs"                      ; shift  ;;
         +ii) _more_qs="Instances[].InstanceId|join(', ',@),$_more_qs"  ; shift  ;;
         +ih) _more_qs="Instances[].HealthStatus|join(', ',@),$_more_qs"; shift  ;;
         +lb) _more_qs="LoadBalancerNames[]|join(', ',@),$_more_qs"     ; shift  ;;
         +mr) _more_qs="Tags[?Key=='MachineRole'].Value|[0],$_more_qs"  ; shift  ;;
          +p) _more_qs="Tags[?Key=='Project'].Value|[0],$_more_qs"      ; shift  ;;
          +v) _more_qs="Tags[?Key=='VPCName'].Value|[0],$_more_qs"      ; shift  ;;
          -h) echo "$_USAGE"                                            ; return ;;
           *) echo "$_USAGE"                                            ; return ;;
      esac
   done
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_regions; do
         if [ -z "$_reg_exp" ]; then
            $_awsasdasg_cmd --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeAutoScalingGroups' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         else
            $_awsasdasg_cmd --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         fi
      done
   else
      if [ -z "$_reg_exp" ]; then
         $_awsasdasg_cmd --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeAutoScalingGroups' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      else
         $_awsasdasg_cmd --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      fi
   fi
}

function awsdi () {
# some 'aws ec2 describe-instances' hacks
   local _USAGE="usage: \
awsdi [OPTIONS]
  -e ENVIRON   # filter results by this Environment (e.g. production, staging)
  -n NAME      # filter results by this Instance Name
  -p PROJECT   # filter results by this Project
  -s STATE     # filter results by this State (e.g. running, terminated, etc.)
  -m MAX       # the maximum number of items to display
  -r REGION    # the Region to query (default: us-west-2)
  +az          # show Availability Zone
  +a           # show AMI (ImageId)
  +bt          # show Branch Tag
  +cc          # show Charge Code
  +c           # show Cluster
  +e           # show Env (Environment)
  +it          # show Instance Type
  +mr          # show Machine Role
  +p           # show Project
  +pi          # show Public IP
  +si          # show Security Group Id(s)
  +sn          # show Security Group Name(s)
  +v           # show VPC Name
  -h           # help (show this message)
default display:
  Inst name | Private IP | Instance ID | State"
   local _awsec2di_cmd="aws ec2 describe-instances"
   local _max_items=""
   local _region="us-west-2"
   local _regions="us-west-1 us-west-2 us-east-1 eu-west-1 eu-central-1"
   local _filters=""
   local _queries="Tags[?Key=='Name'].Value|[0],PrivateIpAddress,InstanceId,State.Name"
   local _more_qs=""
   local _query="Reservations[].Instances[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -p) _filters="Name=tag:Project,Values=*$2* $_filters"         ; shift 2;;
          -n) _filters="Name=tag:Name,Values=*$2* $_filters"            ; shift 2;;
          -s) _filters="Name=instance-state-name,Values=*$2* $_filters" ; shift 2;;
          -e) _filters="Name=tag:Env,Values=*$2* $_filters"             ; shift 2;;
          -m) _max_items="--max-items $2"                               ; shift 2;;
          -r) _region=$2                                                ; shift 2;;
          +a) _more_qs="ImageId,$_more_qs"                              ; shift  ;;
         +az) _more_qs="Placement.AvailabilityZone,$_more_qs"           ; shift  ;;
         +bt) _more_qs="Tags[?Key=='BranchTag'].Value|[0],$_more_qs"    ; shift  ;;
         +cc) _more_qs="Tags[?Key=='ChargeCode'].Value|[0],$_more_qs"   ; shift  ;;
          +c) _more_qs="Tags[?Key=='Cluster'].Value|[0],$_more_qs"      ; shift  ;;
          +e) _more_qs="Tags[?Key=='Env'].Value|[0],$_more_qs"          ; shift  ;;
         +it) _more_qs="InstanceType,$_more_qs"                         ; shift  ;;
         +mr) _more_qs="Tags[?Key=='MachineRole'].Value|[0],$_more_qs"  ; shift  ;;
          +p) _more_qs="Tags[?Key=='Project'].Value|[0],$_more_qs"      ; shift  ;;
         +pi) _more_qs="PublicIpAddress,$_more_qs"                      ; shift  ;;
         +si) _more_qs="SecurityGroups[].GroupId|join(', ',@),$_more_qs"; shift  ;;
         +sn) _more_qs="SecurityGroups[].GroupName|join(', ',@),$_more_qs"; shift  ;;
          +v) _more_qs="Tags[?Key=='VPCName'].Value|[0],$_more_qs"      ; shift  ;;
          -h) echo "$_USAGE"                                            ; return ;;
           *) echo "$_USAGE"                                            ; return ;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_regions; do
         $_awsec2di_cmd --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_awsec2di_cmd --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsdlb () {
# some 'aws elb describe-load-balancer' hacks
   local _USAGE="usage: \
awsdlb [OPTIONS]
  -n NAME      # filter results by this Launch Config Name
  -m MAX       # the maximum number of items to display
  -r REGION    # the Region to query (default: us-west-2)
  +az          # show Availability Zones
  +d           # show DNS Name
  +hc          # show Health Check info (HTH, Int, T, TO, UTH)
  +i           # show Instances
  +li          # show Listeners (LB Port/Proto, Inst Port/Proto)
  +s           # show Scheme
  +sg          # show Security Groups
  +sn          # show Subnets
  -h           # help (show this message)
default display:
  Load Balancer name"
   local _awselbdlb_cmd="aws elb describe-load-balancers"
   local _max_items=""
   local _region="us-west-2"
   local _regions="us-west-1 us-west-2 us-east-1 eu-west-1 eu-central-1"
   local _reg_exp=""
   local _queries="LoadBalancerName"
   local _more_qs=""
   local _query="LoadBalancerDescriptions[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -n) _reg_exp="$2"                                          ; shift 2;;
          -m) _max_items="--max-items $2"                            ; shift 2;;
          -r) _region=$2                                             ; shift 2;;
         +az) _more_qs="AvailabilityZones[]|join(', '@),$_more_qs"   ; shift  ;;
          +d) _more_qs="DNSName,$_more_qs"                           ; shift  ;;
         +hc) _more_qs="HealthCheck.HealthyThreshold,HealthCheck.Interval,HealthCheck.Target,HealthCheck.Timeout,HealthCheck.UnhealthyThreshold,$_more_qs"; shift;;
          +i) _more_qs="Instances[].InstanceId|join(', '@),$_more_qs"; shift;;
         +li) _more_qs="ListenerDescriptions[0].Listener.LoadBalancerPort,ListenerDescriptions[0].Listener.Protocol,ListenerDescriptions[0].Listener.InstancePort,ListenerDescriptions[0].Listener.InstanceProtocol,$_more_qs"; shift;;
          +s) _more_qs="Scheme,$_more_qs"                            ; shift  ;;
         +sg) _more_qs="SecurityGroups|join(', ',@),$_more_qs"       ; shift  ;;
         +sn) _more_qs="Subnets[]|join(', '@),$_more_qs"             ; shift  ;;
          -h) echo "$_USAGE"                                         ; return ;;
           *) echo "$_USAGE"                                         ; return ;;
      esac
   done
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_regions; do
         if [ -z "$_reg_exp" ]; then
            $_awselbdlb_cmd --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLoadBalancers' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         else
            $_awselbdlb_cmd --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         fi
      done
   else
      if [ -z "$_reg_exp" ]; then
         $_awselbdlb_cmd --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLoadBalancers' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      else
         $_awselbdlb_cmd --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      fi
   fi
}

function awsdlc () {
# some 'aws autoscaling describe-launch-configurations' hacks
   local _USAGE="usage: \
awsdlc [OPTIONS]
  -n NAME      # filter results by this Launch Config Name
  -m MAX       # the maximum number of items to display
  -r REGION    # the Region to query (default: us-west-2)
  +ip          # show IAM Instance Profile
  +kn          # show Key Name
  +pt          # show Placement Tenancy
  +sg          # show Security Groups
  -h           # help (show this message)
default display:
  Launch Config name | AMI ID | Instance Type | Region"
   local _awsasdlc_cmd="aws autoscaling describe-launch-configurations"
   local _max_items=""
   local _region="us-west-2"
   local _regions="us-west-1 us-west-2 us-east-1 eu-west-1 eu-central-1"
   local _reg_exp=""
   local _queries="LaunchConfigurationName,ImageId,InstanceType"
   local _more_qs=""
   local _query="LaunchConfigurations[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -n) _reg_exp="$2"                                   ; shift 2;;
          -m) _max_items="--max-items $2"                     ; shift 2;;
          -r) _region=$2                                      ; shift 2;;
         +ip) _more_qs="IamInstanceProfile,$_more_qs"         ; shift  ;;
         +kn) _more_qs="KeyName,$_more_qs"                    ; shift  ;;
         +pt) _more_qs="PlacementTenancy,$_more_qs"           ; shift  ;;
         +sg) _more_qs="SecurityGroups|join(', ',@),$_more_qs"; shift  ;;
          -h) echo "$_USAGE"                                  ; return ;;
           *) echo "$_USAGE"                                  ; return ;;
      esac
   done
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_regions; do
         if [ -z "$_reg_exp" ]; then
            $_awsasdlc_cmd --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLaunchConfigurations' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         else
            $_awsasdlc_cmd --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         fi
      done
   else
      if [ -z "$_reg_exp" ]; then
         $_awsasdlc_cmd --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLaunchConfigurations' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      else
         $_awsasdlc_cmd --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      fi
   fi
}

function awsdni () {
# some 'aws ec2 describe-network-interfaces' hacks
   local _USAGE="usage: \
awsdni [OPTIONS]
  -a  AZ       # filter by Availability Zone (RegEx)
  -d  DESC     # filter by Description
  -i  IP_PRIV  # filter by Private IP
  -id ID       # filter by Interface ID
  -p  IP_PUB   # filter by Public IP
  -r  REGION   # the Region to query (default: us-west-2)
  -s  STATUS   # filter by Status (e.g. in-use, etc.)
  +az          # show Availability Zone
  +m           # show MAC Address
  +p           # show Public IPs
  +s           # show Subnet ID
  +si          # show Security Group Id(s)
  +sn          # show Security Group Name(s)
  +v           # show VPC ID
  -h           # help (show this message)
default display:
  ID | Description | Private IP | Status"
   local _awsec2dni_cmd="aws ec2 describe-network-interfaces"
   local _max_items=""
   local _region="us-west-2"
   local _regions="us-west-1 us-west-2 us-east-1 eu-west-1 eu-central-1"
   local _filters=""
   local _queries="NetworkInterfaceId,Description,PrivateIpAddress,Status"
   local _more_qs=""
   #local _query="NetworkInterfaces[].Instances[]"
   local _query="NetworkInterfaces[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -a) _filters="Name=availability-zone,Values=*$2* $_filters"; shift 2;;
          -d) _filters="Name=description,Values=*$2* $_filters"; shift 2;;
          -i) _filters="Name=addresses.private-ip-address,Values=*$2* $_filters"; shift 2;;
         -id) _filters="Name=network-interface-id,Values=*$2* $_filters"; shift 2;;
          -p) _filters="Name=association.public-ip,Values=*$2* $_filters"; shift 2;;
          -r) _region=$2                                                ; shift 2;;
          -s) _filters="Name=status,Values=*$2* $_filters"; shift 2;;
         +ai) _more_qs="PrivateIpAddresses[].PrivateIpAddress|join(', ',@),$_more_qs"; shift  ;;
         +az) _more_qs="AvailabilityZone,$_more_qs"                     ; shift  ;;
          +m) _more_qs="MacAddress,$_more_qs"                     ; shift  ;;
          +p) _more_qs="Association.PublicIp,$_more_qs"; shift  ;;
          +s) _more_qs="SubnetId,$_more_qs"                     ; shift  ;;
         +si) _more_qs="Groups[].GroupId|join(', ',@),$_more_qs"; shift  ;;
         +sn) _more_qs="Groups[].GroupName|join(', ',@),$_more_qs"; shift  ;;
          +v) _more_qs="VpcId,$_more_qs"                     ; shift  ;;
          -h) echo "$_USAGE"                                            ; return ;;
           *) echo "$_USAGE"                                            ; return ;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_regions; do
         #$_awsec2dni_cmd --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeNetworkInterfaces' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         $_awsec2dni_cmd --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeNetworkInterfaces' | sort | sed 's/^| *//;s/ *| */|/g;s/ *|$/|'"$_region"'/' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_awsec2dni_cmd --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeNetworkInterfaces' | sort | sed 's/^| *//;s/ *| */|/g;s/ *|$//g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsrlrrs () {
# some 'aws route53 list-resource-record-sets' hacks
   local _USAGE="usage: \
awsrlrrs DNS_NAME [OPTIONS]
  -d DNS_NAME # the DNS Name or Hosted Zone to query
  -m MAX      # the maximum number of items to display
  -n NAME     # filter results by this Record Name
  -t TYPE     # record TYPE to display
  +s          # show Set Identifier
  +t          # show TTL
  +w          # show Weight
  -h          # help (show this message)
default display:
  Record Name | Type | Record Value"
   local _awsrlrrs_cmd="aws route53 list-resource-record-sets"
   local _max_items=""
   local _rec_type="*"
   local _queries="Name,Type,ResourceRecords[].Value|[0]"
   local _reg_exp=""
   local _more_qs=""
   while [ $# -gt 0 ]; do
      case $1 in
          -d) _dns_name="$2"                    ; shift 2;;
          -m) _max_items="--max-items $2"       ; shift 2;;
          -n) _reg_exp="$2"                     ; shift 2;;
          -t) _rec_type="?Type=='$2'"           ; shift 2;;
          +s) _more_qs="SetIdentifier,$_more_qs"; shift  ;;
          +t) _more_qs="TTL,$_more_qs"          ; shift  ;;
          +w) _more_qs="Weight,$_more_qs"       ; shift  ;;
          -h) echo "$_USAGE"                    ; return ;;
           *) echo "$_USAGE"                    ; return ;;
      esac
   done
   [ -z "$_dns_name" ] && { echo "error: did not specify DNS_NAME"; echo "$_USAGE"; return; }
   local _query="ResourceRecordSets[$_rec_type]"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_queries]"
   # get the Hosted Zone Id
   hosted_zone_id=$(aws route53 list-hosted-zones-by-name --dns-name $_dns_name --max-items 1 | jq -r .HostedZones[].Id)
   if [ -z "$_reg_exp" ]; then
      $_awsrlrrs_cmd --hosted-zone-id $hosted_zone_id --query "$_query" --output table | egrep -v '^[-+]|ListResourceRecordSets' | sort | sed 's/^| //;s/ |$//g;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   else
      $_awsrlrrs_cmd --hosted-zone-id $hosted_zone_id --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$//g;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function bash_prompt () {
   # get Ansible version
   ansible_version=$(ansible --version 2>/dev/null | head -1 | awk '{print $NF}')
   PS_ANS="${PCYN}Ans:$ansible_version$PNRM"
   # get Python version
   python_version=$(python --version 2>&1 | awk '{print $NF}')
   PS_PY="${PMAG}Py:$python_version$PNRM"
   # get git info
   local git_branch=$(git branch 2>/dev/null|grep '^*'|colrm 1 2)
   git_status=$(git status --porcelain 2> /dev/null)
   # for the future to get fancy
   ##if [[ $git_status =~ ($'\n'|^).M ]]; then local has_modifications=true; fi
   ##if [[ $git_status =~ ($'\n'|^)M ]]; then local has_modifications_cached=true; fi
   ##if [[ $git_status =~ ($'\n'|^)A ]]; then local has_adds=true; fi
   ##if [[ $git_status =~ ($'\n'|^).D ]]; then local has_deletions=true; fi
   ##if [[ $git_status =~ ($'\n'|^)D ]]; then local has_deletions_cached=true; fi
   ##if [[ $git_status =~ ($'\n'|^)[MAD] && ! $git_status =~ ($'\n'|^).[MAD\?] ]]; then local ready_to_commit=true; fi
   if [ -n "$git_status" ]; then
      PS_GIT="$PYLW$git_branch$PNRM"
   else
      PS_GIT="$PNRM$git_branch$PNRM"
   fi
   PS_PATH="$PGRN\w$PNRM [$PS_GIT]"
   PS_WHO="$PBLU\u@\h$PNRM"
   # different themes
   ##PS1="$PS_PROJ $PS_GIT $PS_ANS $PS_PY $PGRN\w$PBLU\n\u@\h$PNRM|$PS_COL$ $PNRM"
   ##PS1="$PS_GIT $PS_ANS $PS_PY $PGRN\w$PBLU\n$PS_PROJ\u@\h$PNRM|$PS_COL$ $PNRM"
   ##PS1="$PGRN\w$PNRM [$PS_GIT]  $PS_ANS  $PS_PY\n$PS_PROJ$PBLU\u@\h$PNRM|$PS_COL$ $PNRM"
   ##PS1="\n$PS_PATH $PS_ANS $PS_PY\n$PS_PROJ$PS_WHO|$PS_COL$ $PNRM"
   ##PS1="\n$PS_ANS $PS_PY $PS_PATH\n$PS_PROJ$PS_WHO|$PS_COL$ $PNRM"
   PS1="\n$PS_ANS $PS_PY $PS_PATH\n$PS_PROJ$PS_WHO[\j]$PS_COL$ $PNRM"
}

function ccc () {
# Synchronize tmux windows
   for I in $@; do
      tmux splitw "ssh $I"
      tmux select-layout tiled
   done
   tmux set-window-option synchronize-panes on
   exit
}

function chkrepodiffs () {	# TOOL
# checks files in current dir against file in home dir for diffs
# only works on https://github.com/pataraco/bash_aliases repo now
# usage: chkrepodiffs [-v] [file]
   local _verbose=$1
   local _files=$2
   local _file
   [ -z "$_files" ] && _files=$(ls -A -I .git)
   for _file in $_files; do
      if [ -e ~/$_file ]; then
         diff -q $_file ~/$_file
         if [ $? -eq 1 ]; then
            if [ "$_verbose" == "-v" ]; then
              diff $_file ~/$_file | \less -rX
            fi
         fi
      fi
   done
}

function chksums () {	# TOOL
# Generate 4 kinds of different checksums for a file
   if [ $# -eq 1 ]; then
      file=$1
      echo "File: $file"
      echo "-------------"
      echo -n "cksum : "
      cksum $file | awk '{print $1}'
      echo -n "md5sum: "
      md5sum $file | awk '{print $1}'
      echo -n "shasum: "
      shasum $file | awk '{print $1}'
      echo -n "sum   : "
      sum $file
   else
      echo "you didn't specify a file to calculate the checksums for"
   fi
}

function cktj () {	# TOOL
# convert a key file so that it can be used in a json entry (i.e. change \n -> "\n")
   if [ -n "$1" ]; then
      cat $1 | tr '\n' '_' | sed 's/_/\\n/g'
      echo
   else
      echo "error: you did not specify a key file to convert"
   fi
}

function compare_lines () {
# compare two lines and colorize the diffs
   local line1="$1 "
   local line2="$2 "
   local line1diffs
   local line2diffs
   local newword
   local word
   for word in $line1; do
      echo "$line2" | \fgrep -q -- "$word "
      if [ $? -eq 1 ]; then
         newword="${RED}$word${NRM}"
      else
         newword=$word
      fi
      line1diffs="$line1diffs $newword"
   done
   line1diffs=`echo "$line1diffs" | sed 's/^ //'`
   for word in $line2; do
      echo "$line1" | \fgrep -q -- "$word "
      if [ $? -eq 1 ]; then
         newword="${GRN}$word${NRM}"
      else
         newword=$word
      fi
      line2diffs="$line2diffs $newword"
   done
   line2diffs=`echo "$line2diffs" | sed 's/^ //'`
   echo -e "\t--------------------- missing in red ---------------------"
   echo -e "$line1diffs"
   echo -e "\t--------------------- added in green ---------------------"
   echo -e "$line2diffs"
}

# THIS IS COMMENTED OUT BECAUSE IT WAS FOR A PREVIOUS PLACE OF EMPLOYMENT USING INFORMIX
# TODO: UPDATE FOR MYSQL AND UNCOMMENT
##function dbgrep () {	# TOOL
### search/grep informix DB for patterns in tables/column names
### OPTIONS
### -w search for whole words only
### -t search table  names for a pattern:
###     display "matching table names"
### -c search column names for a pattern:
###     display "matching column names"
### -i search table  names for a pattern and get info:
###     display "table name: column1, column2, etc."
### -a search for tables containing patterns in column name:
###     display "table name1, table name2, etc."
## NOT_VALID_HOSTS="jump1 jump2 stcgxyjmp01"
## USAGE="dbgrep [-w] -t|c|i|a PATTERN"
##
##   echo "$NOT_VALID_HOSTS" | grep -w $HOSTNAME >/dev/null 2>&1
##   if [ $? -eq 0 ]; then
##      echo "can't run this on any of these hosts: '$NOT_VALID_HOSTS'"
##      return
##   fi
##   grepopt="-i"
##   searchtype="containing"
##   if [ $# -eq 3 ]; then
##      if [ $1 = "-w" ]; then
##         grepopt="-iw"
##         searchtype="matching"
##         shift
##      else
##         echo "usage: $USAGE"
##         return
##      fi
##   fi
##   if [ $# -eq 2 ]; then
##      option=$1
##      pattern=$2
##      case $option in
##         -t)
##            echo "table name(s) $searchtype '$pattern':"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null|grep $grepopt "$pattern"`; do
##               echo $table | grep $grepopt "$pattern"
##            done
##            echo "======"
##            if [ "$searchtype" = "matching" ]; then
##               echo "select tabname from systables where tabname='$pattern'"|dbaccess dev
##            else
##               echo "select tabname from systables where tabname like '%$pattern%'"|dbaccess dev
##            fi
##            ;;
##         -c)
##            echo "column name(s) $searchtype '$pattern' (be patient):"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null`; do
##               echo "info columns for $table"|dbaccess dev 2>/dev/null|awk '{print $1}'|grep $grepopt "$pattern"
##            done|sort -u
##            ;;
##         -i)
##            echo "info about table name(s) $searchtype '$pattern':"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null|grep $grepopt "$pattern"`; do
##               echo $table | grep $grepopt "$pattern" >/dev/null 2>&1
##               if [ $? -eq 0 ]; then
##                  echo "table: $table"
##                  echo "info columns for $table"|dbaccess dev 2>/dev/null
##                  echo "	-------"
##               fi
##            done
##            ;;
##         -a)
##            echo "table name(s) with column(s) $searchtype '$pattern':"
##            for table in `echo "info tables"|dbaccess dev 2>/dev/null`; do
##               columns=`echo "info columns for $table"|dbaccess dev 2>/dev/null|awk '{print $1}'|grep $grepopt "$pattern"`
##               if [ $? = 0 ]; then
##                  for column in $columns; do
##                     printf "%-20s: %s\n" $table $column
##                  done
##               fi
##            done
##            ;;
##         * )
##            echo "usage: $USAGE"
##            ;;
##      esac
##   else
##      echo "usage: $USAGE"
##   fi
##}

function decimal_to_base32 () {
# convert a decimal number to base 32
   BASE32=($(echo {0..9} {a..v}))
   arg1=$@
   for i in $(bc <<< "obase=32; $arg1"); do
      echo -n ${BASE32[$(( 10#$i ))]}
   done && echo
}

function decimal_to_base36 () {
# convert a decimal number to base 36
   BASE36=($(echo {0..9} {a..z}))
   arg1=$@
   for i in $(bc <<< "obase=36; $arg1"); do
      echo -n ${BASE36[$(( 10#$i ))]}
   done && echo
}

function decimal_to_baseN () {
# convert a decimal number to any base
   DIGITS=($(echo {0..9} {a..z}))
   if [ $# -eq 2 ]; then
      base=$1
      if [ $base -lt 2 -o $base -gt 36 ]; then
         echo "base must be between 2 and 36"
         return 2
      fi
      shift
      decimal=$@
      if [ $base -le 16 ]; then
         echo "obase=$base; $decimal" | bc | tr '[:upper:]' '[:lower:]'
      else
         for i in $(bc <<< "obase=$base; $decimal"); do
            echo -n ${DIGITS[$(( 10#$i ))]}
         done && echo
      fi
      else
      echo "usage: decimal_to_base BASE_DESIRED DECIAML_NUMBER"
   fi
   return 0
}

function elbinsts () {
# convert instance ids to instance names that are attached to an AWS ELB
   local _elb_name=$1
   local _region=$2
   local _inst_id
   local _inst_id_states=$(aws elb describe-instance-health --region $_region --load-balancer-name $_elb_name --query "InstanceStates[].[InstanceId,State,Reasoncode]" --output table | \grep '^|.*i-[0-9a-z]' | sed 's/|  /| /g;s/^| //;s/ \+|$//')
   local _inst_ids=$(echo "$_inst_id_states" | awk '{print $1}')
   if [ -n "$_inst_ids" ]; then
      while read line; do
         _inst_id=$(echo "$line" | awk '{print $3}')
         _inst_id_state=$(echo "$_inst_id_states" | grep $_inst_id)
         echo "$line" | sed "s/$_inst_id/$_inst_id_state/"
      done <<< "`aws ec2 describe-instances --region $_region --instance-ids $_inst_ids --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value|[0],InstanceId]" --output table | egrep -v '^[-+]|Describe' | sort | sed 's/|  /| /g;s/^| //;s/ \+|$//'`"
   else
      echo "not found"
   fi
}

function gdate () {
# convert hex date value to date
   date --date=@`printf "%d\n" 0x$1`
}

function getpubkey () {	# CTCS
# get user's public key from cloud_automation users role
   local _USERS_ROLE_PATH=~/cloud_automation/ansible/roles/users
   local _user=$1
   if [ "$_user" ]; then
      grep -r "ssh.*$_user" $_USERS_ROLE_PATH | cut -d'"' -f2
   else
      echo "usage: getpubkey USER"
   fi
}

##function getramsz () {	# TOOL
### get the amount of RAM on a server
## JUMP_SERVERS="jump1 jump2 stcgxyjmp01"
## USAGE="usage: getramsz [server] [server2] [server3]..."
##   echo "$JUMP_SERVERS" | grep -w $HOSTNAME >/dev/null 2>&1
##   if [ $? -eq 0 -a $# -gt 0 ]; then
##      servers="$*"
##      remote=true
##   elif [ $# -eq 0 ]; then
##      servers=$HOSTNAME
##      remote=false
##   else
##      echo "$USAGE"
##      return
##   fi
##   for server in $servers; do
##      host $server > /dev/null
##      if [ $? -eq 0 ]; then
##         total_mem=0
##         echo -n "$server: RAM installed: 'hpasmcli' calculating... "
##         if [ "$remote" = "true" ]; then
##            #for dimm_size in `ssh ecisupp@$server 'hpasmcli -s "show dimm" | grep Size' 2>/dev/null | awk '{print $2}'`; do
##            for dimm_size in `ssh -q ecisupp@$server 'hpasmcli -s "show dimm" | grep Size' 2>/dev/null | awk '{print $2}'`; do
##               total_mem=`expr $total_mem + $dimm_size`
##            done
##         else
##            for dimm_size in `hpasmcli -s "show dimm" | grep Size 2>/dev/null | awk '{print $2}'`; do
##               total_mem=`expr $total_mem + $dimm_size`
##            done
##         fi
##         if [ $total_mem -eq 0 ]; then
##            hpasmcli_val="( ERROR )"
##         else
##            total_mem_gb=`expr $total_mem / 1024`
##            hpasmcli_val=`printf "[ %2d GB ]" $total_mem_gb`
##         fi
##         echo -ne "\r$server: RAM installed: 'hpasmcli' $hpasmcli_val... 'free' calculating... "
##         if [ "$remote" = "true" ]; then
##            #free_size=`ssh ecisupp@$server 'free | grep Mem' 2>/dev/null | awk '{print $2}'`
##            free_size=`ssh -q ecisupp@$server 'free | grep Mem' 2>/dev/null | awk '{print $2}'`
##         else
##            free_size=`free | grep Mem 2>/dev/null | awk '{print $2}'`
##         fi
##         [ -z "$free_size" ] && free_size=0
##         if [ $free_size -eq 0 ]; then
##            free_val="( ERROR )"
##         else
##            free_mem_gb=`expr $free_size / 1024 / 1024 + 1`
##            free_val=`printf "[ %2d GB ]" $free_mem_gb`
##         fi
##         echo -e "\r$server: RAM installed: 'hpasmcli' $hpasmcli_val... 'free' $free_val\e[K"
##      else
##         echo -n "$server: unknown host"
##      fi
##   done
##}

function gh () {	# TOOL
   if [[ $1 =~ ^\^.* ]]; then
      pattern=$(echo "$*" | tr -d '^')
      #echo "looking for: ^[0-9]*  $pattern"
      history | grep "^[0-9]*  $pattern" | grep $pattern
   else
      #echo "looking for: $*"
      history | grep "$*"
   fi
}

function listcrts () {
# list all info in a crt bundle
# usage:
#    listcrts [cert_file] [openssl_options]
#       cert_file       (arg 1) - name of cert file
#         (optional - otherwise all *.crt files)
#       openssl_options (arg 2) - openssl options
#         (e.g. -subject|dates|text|serial|pubkey|modulus
#               -purpose|fingerprint|alias|hash|issuer_hash)
#    (default options: -subject -dates -issuer and always: -noout)
   local _DEFAULT_OPENSSL_OPTS="-subject -dates -issuer"
   local _cbs _cb
   local _cert_bundle=$1
   if [ "${_cert_bundle: -3}" == "crt" ]; then
      shift
   else
      unset _cert_bundle
   fi
   local _openssl_opts=$*
   echo "$_openssl_opts" | grep -q '+[a-z].*'
   if [ $? -eq 0 ]; then
      _openssl_opts="$_DEFAULT_OPENSSL_OPTS $(echo "$_openssl_opts" | sed 's/+/-/g')"
   fi
   _openssl_opts=${_openssl_opts:=$_DEFAULT_OPENSSL_OPTS}
   _openssl_opts="$_openssl_opts -noout"
echo "opts: '$_openssl_opts'"
   if [ -z "$_cert_bundle" ]; then
      ls *.crt > /dev/null 2>&1
      if [ $? -eq 0 ]; then
         echo "certificate(s) found"
         _cbs=$(ls *.crt)
      else
         echo "no certificate files found"
         return
      fi
   else
      _cbs=$_cert_bundle
   fi
   for _cb in $_cbs; do
      echo "---------------- ( $_cb ) ---------------------"
      cat $_cb | \
         awk '{\
            if ($0 == "-----BEGIN CERTIFICATE-----") cert=""; \
            else if ($0 == "-----END CERTIFICATE-----") print cert; \
            else cert=cert$0}' | \
               while read cert; do
                  [[ $_more ]] && echo "---"
                  echo "$cert" | \
                     base64 -d | \
                        openssl x509 -inform DER $_openssl_opts | \
                           awk '{
                              if ($1~/subject=/)
                                 { gsub("subject=","  sub:",$0); print $0 }
                              else if ($1~/issuer=/)
                                 { gsub("issuer=","isuer:",$0); print $0 }
                              else if ($1~/notBefore/)
                                 { gsub("notBefore=","dates: ",$0); printf $0" -> " }
                              else if ($1~/notAfter/)
                                 { gsub("notAfter=","",$0); print $0 }
                              else if ($1~/[0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z]/)
                                 { print " hash: "$0 }
                              else
                                 { print $0 }
                           }'
                  local _more=yes
               done
   done
}

function listcrts2 () {
   for _c; do
      echo
      echo "Certificate: $_c"
      [ ! -f "$_c" ] && { echo " X - Certificate not found"; continue; }
      _n_cert=$(grep -hc "BEGIN CERTIFICATE" "$_c")
      [ "$_n_cert" -lt 1 ] && { echo " X - Not valid certificate"; continue; }
      for n in $(seq 1 $_n_cert);do
         awk -v n=$n '/BEGIN CERT/ { n -= 1;} n == 0 { print }' "$_c" | \
            openssl x509 -noout -text | sed -n \
               -e 's/^/ o - /' \
               -e 's/ *Signature Algorithm: / signature=/p' \
               -e 's/ *Not Before: / notBefore=/p' \
               -e 's/ *Not After *: / notAfter=/p' \
               -e 's/ *Issuer: / issuer=/p' \
               -e 's/ *Subject: / subject=/p' \
               -e '/Subject Public Key Info/q' | sort -r
         echo " -------------"
      done
   done
}

function mkalias () {	# TOOL
# make an alias and add it to this file
   if [[ $1 && $2 ]]; then
      echo "alias $1=\"$2\"" >> ~/.bash_aliases
      alias $1="$2"
   fi
}

function mktb () {	# MISC
# get rid of all the MISC, RHUG, and TRUG functions from $BRCSRC
# and save the rest to $BRCDST
   local BRCSRC=/home/praco/.bashrc
   local BRCDST=/home/praco/.bashrc.tools
   rm -f $BRCDST
   sed '/^function.*# MISC$/,/^}$/d;/^function.*# RHUG$/,/^}$/d;/^function.*# TRUG$/,/^}$/d' $BRCSRC > $BRCDST
}

function pag () {	# TOOL
   ps auxfw | grep $*
}

function peg () {	# TOOL
   ps -ef | grep $*
}

function pl () {
# run a command and pipe it through `less`
   eval $@ | less
}

function rac () {	# MISC
# remember AWS CLI command - save the given command for later retreval
   COMMAND="$*"
   COMMANDS_FILE=/home/praco/.aws_commands.txt
   echo "$COMMAND" >> $COMMANDS_FILE
   sort $COMMANDS_FILE > $COMMANDS_FILE.sorted
   mv -f $COMMANDS_FILE.sorted $COMMANDS_FILE
   echo "added: '$COMMAND'"
   echo "   to: $COMMANDS_FILE"
}

function rc () {	# MISC
# remember command - save the given command for later retreval
   COMMAND="$*"
   COMMANDS_FILE=/home/praco/.commands.txt
   echo "$COMMAND" >> $COMMANDS_FILE
   sort $COMMANDS_FILE > $COMMANDS_FILE.sorted
   mv -f $COMMANDS_FILE.sorted $COMMANDS_FILE
   echo "added: '$COMMAND'"
   echo "   to: $COMMANDS_FILE"
   ##scp -q $COMMANDS_FILE $OTHERVM:/home/praco
}

function rf () {	# MISC
# remember file - save the given file for later retreval
   FILE="$*"
   FILES_FILE=/home/praco/.files.txt
   echo "$FILE" >> $FILES_FILE
   sort $FILES_FILE > $FILES_FILE.sorted
   mv -f $FILES_FILE.sorted $FILES_FILE
   echo "added '$FILE' to: $FILES_FILE"
   ##scp -q $FILES_FILE $OTHERVM:/home/praco
}

function sae () {	# TOOL
# set AWS environment
   local REPOS=$HOME/repos
   local AWS_CFG=$HOME/.aws/config
   local arg="$1"

   if [ -n "$arg" ]; then
      case $arg in
            corsother) aenv="CORS Others"               ;;
              combain) aenv="ENT Combain"               ;;
            cybrscore) aenv="ENT CYBRScore Development" ;;
               ilpdev) aenv="ENT ILP Development"       ;;
            localblox) aenv="ENT Local Blox"            ;;
                  scm) aenv="ENT SCM"                   ;;
              locapps) aenv="Local Applications (Prod)" ;;
           loctoolkit) aenv="Local ToolKit"             ;;
           telecomsys) aenv="TeleComSys (Dev) 'NavTel'" ;;
                 raco) aenv="Raco's AWS"                ;;
                unset) aenv="Environment un set"        ;;
                    *) echo "WTF? Try: [corsother combain cybrscore ilpdev localblox scm locapps loctoolkit telecomsys raco OR unset]"; return 2 ;;
      esac
      if [ "$arg" != "unset" ]; then
         export AWSPROF=$arg
         export AWSENV=$aenv
         export AWS_DEFAULT_PROFILE=$arg	# for `aws` (instead of using --profile)
         export AWS_ACCESS_KEY_ID=`awk '$2~/'"$AWS_DEFAULT_PROFILE"'/ {pfound="true"}; (pfound=="true" && $1~/aws_access_key_id/) {print $NF;exit}' $AWS_CFG`
         export AWS_SECRET_ACCESS_KEY=`awk '$2~/'"$AWS_DEFAULT_PROFILE"'/ {pfound="true"}; (pfound=="true" && $1~/aws_secret_access_key/) {print $NF;exit}' $AWS_CFG`
         echo "environment has been set to --> $AWSENV"
      else
         unset AWSPROF
         unset AWSENV
         unset AWS_DEFAULT_PROFILE
         unset AWS_ACCESS_KEY_ID
         unset AWS_SECRET_ACCESS_KEY
         echo "environment has been unset"
      fi
      if [ "$COLOR_PROMPT" = yes ]; then
         case $arg in
            unset)						# cyan prompt
               PS_PROJ="$PNRM"; PS_COL="$PCYN" ;;
            corsother|combain|cybrscore|ilpdev|localblox)	# cyan prompt
               PS_PROJ="$PCYN[$AWSPROF]$PNRM"; PS_COL="$PCYN" ;;
            loctoolkit)						# magenta prompt
               PS_PROJ="$PMAG[$AWSPROF]$PNRM"; PS_COL="$PMAG" ;;
            telecomsys)						# yellow prompt
               PS_PROJ="$PYLW[$AWSPROF]$PNRM"; PS_COL="$PYLW" ;;
            scm|locapps)					# red prompt
               PS_PROJ="$PRED[$AWSPROF]$PNRM"; PS_COL="$PRED" ;;
            raco)						# green prompt
               PS_PROJ="$PGRN[$AWSPROF]$PNRM"; PS_COL="$PGRN" ;;
         esac
      fi
   else
      echo "--- ${aenv:=Environment NOT set} ---"
      echo " AWSPROF               = '$AWSPROF'"
      echo " AWSENV                = '$AWSENV'"
      echo " AWS_DEFAULT_PROFILE   = '$AWS_DEFAULT_PROFILE'"
      echo " AWS_ACCESS_KEY_ID     = '$AWS_ACCESS_KEY_ID'"
      echo " AWS_SECRET_ACCESS_KEY = '$AWS_SECRET_ACCESS_KEY'"
   fi
}

function searchtcsrepo () {	# TOOL
   local _grep_pattern="$*"
   #echo "looking for: '$_grep_pattern'"
   aws --profile telecomsys s3 ls tcs-yum-repos/amzn/noarch/data/ | grep "$_grep_pattern"
}

function showf () {	# TOOL
# show a function
   ALIASES_FILE="$HOME/.bash_aliases"
   if [[ $1 ]]; then
      grep -q "^function $1 " $ALIASES_FILE
      if [ $? -eq 0 ]; then
         sed -n '/^function '"$1"' /,/^}/p' $ALIASES_FILE
      else
         echo "function: '$1' - not found"
      fi
   else
      echo
      echo "which function do you want to see?"
      grep "^function .* " $ALIASES_FILE | awk '{print $2}' | cut -d'(' -f1 |  awk -v c=4 'BEGIN{print "\n\t--- Functions (use \`sf\` to show details) ---"}{if(NR%c){printf "  %-18s",$1}else{printf "  %-18s\n",$1}}END{print CR}'
      echo -ne "enter function: "
      read func
      echo
      showf $func
   fi
}

function source_ssh_env () {
   SSH_ENV="$HOME/.ssh/environment"
   if [ -f "$SSH_ENV" ]; then
      source $SSH_ENV > /dev/null
      ps -u $USER | grep -q "$SSH_AGENT_PID.*ssh-agent$" || start_ssh_agent
   else
      start_ssh_agent
   fi
}

function sse () {
# ssh in to a server as user: "ec2-user" and run optional command
   if [ "$1" != "" ]; then
      _server=$1
      shift
      if [ "$*" == "" ]; then
         ssh ec2-user@${_server}
      else
         ssh ec2-user@${_server} "$*"
      fi
   else
      echo "USAGE: sse HOST [COMMAND(S)]"
   fi
}

##function sshc () {	# TOOL
##   source_ssh_env
##   if [ $# -ge 2 ]; then
##      host=$1
##      shift
##      cmd="$*"
##      host $host > /dev/null
##      if [ $? -eq 0 ]; then
##         #ssh ecisupp@$host ''"$cmd"'' 2> /dev/null
##         ssh -q ecisupp@$host ''"$cmd"''
##      else
##         echo "unknown host: $host"
##      fi
##   else
##      echo "you did not specify the 'host' and 'cmd'"
##   fi
##}

function start_ssh_agent () {
   SSH_ENV="$HOME/.ssh/environment"
   echo -n "Initializing new SSH agent... "
   /usr/bin/ssh-agent | sed 's/^echo/#echo/' > $SSH_ENV
   echo "succeeded"
   chmod 600 $SSH_ENV
   source $SSH_ENV > /dev/null
   /usr/bin/ssh-add
}

function stopwatch () {	# TOOL
   trap "return" SIGINT SIGTERM SIGHUP SIGKILL SIGQUIT
   trap 'echo; stty echoctl; trap - SIGINT SIGTERM SIGHUP SIGKILL SIGQUIT RETURN' RETURN
   stty -echoctl # don't echo "^C" when [Ctrl-C] is entered
   local _started _start_secs _current _current_secs
   _started=$(date +'%d-%b-%Y %T')
   _start_secs=$(date +%s -d "$_started")
   echo
   while true; do
      _current=$(date +'%d-%b-%Y %T')
      _current_secs=$(date +%s -d "$_current")
      #echo -ne "\rStart: ${GRN}$_started${NRM} - Finish: ${RED}$_current${NRM} Delta: ${YLW}$(date +%T -d "0 $_current_secs secs - $_start_secs secs secs")${NRM} "
      echo -ne "  Start: ${GRN}$_started${NRM} - Finish: ${RED}$_current${NRM} Delta: ${YLW}$(date +%T -d "0 $_current_secs secs - $_start_secs secs secs")${NRM}\r"
   done
}

function tb () {
   echo -ne "\033]0; $* \007"
}

function tsend () {
# Send same command to all panes
   tmux set-window-option synchronize-panes on
   tmux send-keys "$@" Enter
   tmux set-window-option synchronize-panes off
}

function vagssh () {
# ssh in to our vagrant server in a seperate xterm window
   $XTERM -e 'cd ~/cloud_automation/vagrant/CentOS65/; vagrant ssh' &
}

function vin () {
# vim certain files by alias
   NOTES_DIR="notes"
   note_file=$1
   if [ -n "$note_file" ]; then
      case $note_file in
         ansible) actual_note_file=Ansible_Notes.txt        ;;
             aws) actual_note_file=AWS_Notes.txt            ;;
           awsas) actual_note_file=AWS_AutoScaling_Notes.txt;;
            bash) actual_note_file=Bash_Notes.txt           ;;
          consul) actual_note_file=Consul_Notes.txt         ;;
          docker) actual_note_file=Docker_Notes.txt         ;;
              es) actual_note_file=Elasticsearch_Notes.txt  ;;
             git) actual_note_file=Git_Notes.txt            ;;
            ldap) actual_note_file=LDAP_Notes.txt           ;;
           linux) actual_note_file=Linux_Notes.txt          ;;
        logstash) actual_note_file=Logstash_Notes.txt       ;;
          python) actual_note_file=Python_Notes.txt         ;;
           redis) actual_note_file=Redis_Notes.txt          ;;
             sql) actual_note_file=SQL_Notes.txt            ;;
               *) echo "unknown alias - try again"; return 2;;
      esac
      eval vim $REPO_DIR/$NOTES_DIR/$actual_note_file
   else
      echo "you didn't specify a file (alias) to edit"
   fi
}

function vmbackups () {	# VMedix
# show yesterday's and today's backups for VMedix
   local _USAGE="usage: vmbackups [us|eu] [m|s]"
   local _backup _region _s3_file_base
   local _backups="backups elasticsearch"
   local _regions="us-east-1 eu-west-1"
   while [ $# -gt 0 ]; do
      case $1 in
         us) _regions="us-east-1"    ; shift ;;
         eu) _regions="eu-west-1"    ; shift ;;
          m) _backups="backups"      ; shift ;;
          s) _backups="elasticsearch"; shift ;;
          *) echo "$_USAGE"          ; return;;
      esac
   done
   _mtoday=$(date +%Y-%m-%d)
   _myestr=$(date +%Y-%m-%d -d yesterday)
   _stoday=$(date +%Y_%m_%d)
   _syestr=$(date +%Y_%m_%d -d yesterday)
   for _backup in $_backups; do
      for _region in $_regions; do
         case $_region in
            us-east-1) _s3_file_base=s3://virtumedix-$_backup/$_region   ;;
            eu-west-1) _s3_file_base=s3://virtumedix-eu-$_backup/$_region;;
         esac
         case $_backup in
            backups)
               echo "MongoDB Backups ($_region)"
               aws s3 ls $_s3_file_base/production/dump-$_myestr
               aws s3 ls $_s3_file_base/production/dump-$_mtoday
               aws s3 ls $_s3_file_base/production/dump-latest
            ;;
            elasticsearch)
               echo "ElasticSearch Backups ($_region)"
               aws s3 ls $_s3_file_base/snapshot-$_syestr
               aws s3 ls $_s3_file_base/snapshot-$_stoday
            ;;
         esac
      done
   done
}

function vmchkcrts () {	# TOOL
# check subject, dates and serial of certs installed on app_nginx servers
   local _USAGE="vmchkcrts -p PROJECT [-b|g] -v LIST_OF_VPCS"
   local _AUTOMATION_INV=~/cloud_automation/ansible/inventory
   local project vpcs
   local hosts_file=hosts_production
   while [ $# -gt 0 ]; do
      case $1 in
         -b) hosts_file=hosts_blue; shift  ;;
         -g) hosts_file=hosts_green; shift ;;
         -p) project=$2; shift 2           ;;
         -v) shift; vpcs="$*"; break       ;;
          *) echo "$_USAGE"; return        ;;
      esac
   done
   [ -z "$project" ] && project=VMedix
   [ -z "$vpcs" ] && vpcs="mirkwood isengard"
   for vpc in $vpcs; do
      for domain in $(grep -r server_name: $_AUTOMATION_INV/$project/$vpc | awk '{print $NF}'); do
         for host in $(ansible --list-hosts -i $_AUTOMATION_INV/$project/$vpc/$hosts_file "*app_nginx*" --vault-password-file=~/.vault.vm 2> /dev/null | grep -v 'hosts.*:$'); do
            echo
            echo -n " host: $host | domain: $domain"
            nc -w 2 -z $host 443 > /dev/null 2>&1
            if [ $? -eq 0 ]; then
               echo
               openssl s_client -connect $host:443 -servername $domain </dev/null 2>/dev/null | \
                  openssl x509 -noout -subject -serial -dates | \
                     awk '{
                        if ($1~/subject=/) {
                           gsub("subject=","  sub:",$0)
                           printf $0" "
                        }
                        else if ($1~/notBefore/) {
                           gsub("notBefore=","dates: ",$0)
                           printf $0" "
                        }
                        else if ($1~/notAfter/) {
                           gsub("notAfter=","-> ",$0)
                           print $0
                        }
                        else if ($1~/serial=/) {
                           gsub("serial=","",$0)
                           print "["$0"]"
                        }
                        else {
                           print $0
                        }
                     }'
            else
               echo " - NOT reachable"
            fi
         done
      done
   done
}

function vmcssh () {	# VMedix
# cssh to VMedix servers
   local _USAGE="usage: vmcssh us|eu a|1|2|g|b|p [PATTERN]"
   local _INV_REPO="~/cloud_automation/ansible/inventory/VMedix"
   local _vpc _h _pat
   local _country=$1
   if [[ $_country =~ (us|eu) ]]; then
      case $_country in
         us) _vpc="mirkwood"          ;;
         eu) _vpc="isengard"          ;;
          *) echo "$_USAGE"; return ;;
      esac
   else
      echo "$_USAGE"
      return
   fi
   local _hosts=$2
   if [ -n "$_hosts" ]; then
      case $_hosts in
         a) _pat="*${_vpc}*"       ;;
         1) _h=hosts_shared1       ;;
         2) _h=hosts_shared2       ;;
         g) _h=hosts_green         ;;
         b) _h=hosts_blue          ;;
         p) _h=hosts_production    ;;
         *) echo "$_USAGE"; return ;;
      esac
   else
      echo "$_USAGE"
      return
   fi
   local _pattern=$3
   if [ -n "$_pattern" ]; then
      _pat="*${_pattern}*"
   elif [ -z "$_pat" ]; then
      _pat="all"
   fi
   #debug#echo "repo: $_INV_REPO | vpc: $_vpc | hosts: $_h | pat: $_pat"
   #debug#echo -e "csshing to these hosts:\n$(ansible --list-hosts -i $_INV_REPO/$_vpc/$_h "$_pat" --vault-password-file=~/.vault.vm 2>/dev/null | grep -v 'hosts.*:$')"
   cssh $(ansible --list-hosts -i $_INV_REPO/$_vpc/$_h "$_pat" --vault-password-file=~/.vault.vm 2>/dev/null | egrep -v 'hosts.*:$|localhost$|loghost|vpnhost') &
}

function vmmanageusers () {	# VMedix
# add|remove user keys from AWS instances controled via Ansible
   local _USAGE="usage: vmmanageusers us|eu a|1|2|g|b|p [-l apps|data|PATTERN] add|rem all|USR1 [USR2...]"
   local _REPO_HOME=~/cloud_automation/ansible
   local _INV_REPO=$_REPO_HOME/inventory/VMedix
   local _USERS_ROLE_DEV_VARS=$_REPO_HOME/roles/users/vars/dev_users_present.yml
   local _USERS_ROLE_MAIN_TASK=$_REPO_HOME/roles/users/tasks/main.yml
   local _cmd _disable_opt _disable_usrs _h _pat _st _usr _vpc
   local _country=$1
   if [[ $_country =~ (us|eu) ]]; then
      case $_country in
         us) _vpc=mirkwood          ;;
         eu) _vpc=isengard          ;;
          *) echo "$_USAGE"; return ;;
      esac
   else
      echo "$_USAGE"; return
   fi
   local _hosts=$2
   if [ -n "$_hosts" ]; then
      case $_hosts in
         a) _pat="*${_vpc}*"       ;;
         1) _h=hosts_shared1       ;;
         2) _h=hosts_shared2       ;;
         g) _h=hosts_green         ;;
         b) _h=hosts_blue          ;;
         p) _h=hosts_production    ;;
         *) echo "$_USAGE"; return ;;
      esac
   else
      echo "$_USAGE"; return
   fi
   local _3rd_opt=$3
   if [ "$_3rd_opt" == "-l" ]; then
      local _pattern=$4
      if [ -n "$_pattern" ]; then
         case $_pattern in
            apps) _pat="*ap*" ;;
            data) _pat="mongo*:search*:redis*" ;;
               *) _pat="$_pattern*" ;;
         esac
      else
         echo "$_USAGE"; return
      fi
      _cmd=$5
      shift 5
   else
      _cmd=$3
      shift 3
   fi
   if [ -z "$_pat" ]; then
      _pat=all
   fi
   _pat="'$_pat:!localhost:!logstash*'"
   local _all_tags=$(\grep "tags: \[" $_USERS_ROLE_MAIN_TASK | \grep -v always | sort -u | cut -d"'" -f2 | tr '\n' ',' | sed 's/,$//')
   local _all_but_dev_tags=$(echo $_all_tags | sed "s/dev,//;s/,dev//")
   case $_cmd in
      add) _st="'$_all_but_dev_tags'" ;;
      rem) _st="'$_all_tags'"         ;;
        *) echo "$_USAGE"; return     ;;
   esac
   local _usrs=$*
   local _all_dev_usrs=$(\grep -- "- name:" $_USERS_ROLE_DEV_VARS | awk '{print $NF}' | tr '\n' ',' | sed 's/,$//')
   if [ -n "$_usrs" ]; then
      if [ "$_cmd" == "add" ]; then
         if [ "$_usrs" != "all" ]; then
            for _usr in $_usrs; do
               _disable_usrs=$(echo $_all_dev_usrs | sed "s/\"$_usr\",//;s/,\"$_usr\"//")
               _all_dev_usrs=$_disable_usrs
            done
         fi
      else
         if [ "$_usrs" != "all" ]; then
            _disable_usrs="\"$(echo "$_usrs" | sed 's/ /","/g')\""
         else
            _disable_usrs="$_all_dev_usrs"
         fi
      fi
   else
      echo "$_USAGE"; return
   fi
   if [ "$_cmd" == "add" -a "$_usrs" == "all" ]; then
      _disable_opt=""
   else
      _disable_opt="-e '{\"disable_users\": [$_disable_usrs]}'"
   fi
   echo "ansible-playbook -i $_INV_REPO/$_vpc/$_h --limit "$_pat" --skip-tags "$_st" $_disable_opt --vault-password-file=~/.vault.vm $_REPO_HOME/playbooks/util/manage_users.yml"
   eval ansible-playbook -i $_INV_REPO/$_vpc/$_h --limit "$_pat" --skip-tags "'$_st'" "$_disable_opt" --vault-password-file=~/.vault.vm $_REPO_HOME/playbooks/util/manage_users.yml
}

function vmmopmonit () {	# VMedix
   local _USAGE="usage: vmmopmonit us|eu"
   local _country=$1
   local _vpc
   local _repo="~/cloud_automation/ansible/inventory/VMedix"
   local _region
   case $_country in
      us) _vpc="mirkwood"; _region="us-east-1" ;;
      eu) _vpc="isengard"; _region="eu-west-1" ;;
       *) echo "$_USAGE"; return ;;
   esac
   local _dns_servers=$(egrep -r 'server_name:|api_server:' ~/cloud_automation/ansible/inventory/VMedix/$_vpc | awk '{print $NF}' | paste -s )
   # `sstat` on BLUE api servers
   xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000 -geometry 80x72+7+30 -e 'source ~/.bash_aliases; wutch ''echo -e \"${BLD}${BLU}\\tBlue ${YLW}Cluster services status - ${RED}'"$_vpc"' ['"$_region"']${NRM}\"\; ansible -i '"$_repo/$_vpc"'/hosts_blue \"*api[0-9]*\" -a \"sstat\" --vault-password-file ~/.vault.vm 2>/dev/null \| egrep -v \"WARN\|duplicate\|cloud_auto\|SUCCESS\"''' &
   # `sstat` on GREEN api servers
   xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000 -geometry 80x72+523+30 -e 'source ~/.bash_aliases; wutch ''echo -e \"${BLD}${GRN}\\tGreen ${YLW}Cluster services status - ${RED}'"$_vpc"' ['"$_region"']${NRM}\"\; ansible -i '"$_repo/$_vpc"'/hosts_green \"*api[0-9]*\" -a \"sstat\" --vault-password-file ~/.vault.vm 2>/dev/null \| egrep -v \"WARN\|duplicate\|cloud_auto\|SUCCESS\"''' &
   # `crond` service status on all app, mongo and redis servers
   xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000 -geometry 86x22+1038+30 -e 'source ~/.bash_aliases; wutch ''echo -e \"${BLD}${YLW}\\tcrond Service Statuses - ${RED}'"$_vpc"' ['"$_region"']${NRM}\\n\"\; ansible -i '"$_repo/$_vpc"'/hosts_production \"*ap*:mongo*:redis*\" -m shell -a \"/sbin/service crond status\" --vault-password-file ~/.vault.vm \| tr -d \"\\n\" \| sed \"s/\>\>/: /g\;s/running\.\.\./\`printf \"\\033[1\;32mrunning\\033[m\"\`\\n/g\;s/stopped/\`printf \"\\033[1\;31mstopped\\033[m\"\`\\n/g\" \| sort''' &
   # AWS CloudWatch alarms
   xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000 -geometry 86x48+1038+358 -e 'source ~/.bash_aliases; wutch ''echo -e \"${BLD}${YLW}\\tCloudWatch Alarms - ${RED}'"$_vpc"' ['"$_region"']\\n${NRM}\"\; aws cloudwatch describe-alarms --region '"$_region"' --profile locapps \| grep AlarmName \| grep -i VMedix \| sed \"s/^ *//\;s/green/\`printf \"\\033[1\;32mgreen\\033[m\"\`/g\;s/blue/\`printf \"\\033[1\;34mblue\\033[m\"\`/g\"''' &
   # AWS Route53/DNS entries showing active cluster
   xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000 -geometry 123x26+7-52 -e 'source ~/.bash_aliases; wutch ''echo -e \"${BLD}${YLW}\\tDNS Entries - ${RED}'"$_vpc"' ['"$_region"']${NRM}\\n\"\; for h in '"$_dns_servers"'\; do dig \$h \| egrep -v \"^$\|^\;\" \| grep CNAME \| sed \"s/green/\`printf \"\\033[1\;32mgreen\\033[m\"\`/g\;s/blue/\`printf \"\\033[1\;34mblue\\033[m\"\`/g\;s/\\\(\\s\\+[0-9]\\+\\s\\+\\\)/\`printf \"\\033[1\;36m\"\`\\1\`printf \"\\033[m\"\`/g\"\; done''' &
   # AWS ASG of app servers showing Health Check Type
   xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000 -geometry 129x19+781-52 -e 'source ~/.bash_aliases; wutch ''echo -e \"${BLD}${YLW}\\tAWS AutoScalingGroup Descriptions - ${RED}'"$_vpc"' ['"$_region"']${NRM}\\n\"\; aws autoscaling describe-auto-scaling-groups --profile locapps --region '"$_region"' --query \"AutoScalingGroups[].[AutoScalingGroupName,LaunchConfigurationName,length\(Instances\),DesiredCapacity,MinSize,MaxSize,HealthCheckType,Instances[].HealthStatus\|join\('"\'"', '"\'"',@\),LoadBalancerNames[0]]\" --output table \| egrep -- \"-ap[i,p]\" \| sed \"s/ //g\" \| column -s\"\|\" -t \| sed \"s/\\\(  \\\)\\\([a-zA-Z0-9]\\\)/\| \\2/g\;s/green/\`printf \"\\033[1\;32mgreen\\033[m\"\`/g\;s/blue/\`printf \"\\033[1\;34mblue\\033[m\"\`/g\;s/EC2/\`printf \"\\033[1\;33mEC2\\033[m\"\`/g\;s/ELB/\`printf \"\\033[1\;36mELB\\033[m\"\`/g\"''' &
   #TODO website status?
}

function vmmopprep () {	# VMedix
# grab steps in PCR steps file and add to history file to easily execute them
# must specify one of "-s|p|r" (staging|production|roll-back) steps desired
# and the PCR steps file
   local _ANSIBLE_HOME=~/cloud_automation/ansible
   local _USAGE="usage: vmmopprep -s|t|p|r [PCR_Steps_File]"
   local _STEPS=/tmp/.mop_steps
   echo -n "changing working dir to   : "
   if cd $_ANSIBLE_HOME; then
      echo -e "[${CYN}$_ANSIBLE_HOME${NRM}]"
   else
      echo -e "[${CYN}FAILED${NRM}]"
      echo "couldn't change working dir to: $_ANSIBLE_HOME"
      return
   fi
   local _GIT_BRANCH=$(git branch 2>/dev/null|grep '^*'|colrm 1 2)
   [ $# -lt 1 ] && { echo -e "${RED}ERROR${NRM}: not enough arguments\n$_USAGE"; return; }
   local pcr_steps_file=$2
   if [ -z "$pcr_steps_file" ]; then
      echo -e "no PCR Steps File given   : [${CYN}using git branch: $_GIT_BRANCH${NRM}]"
      pcr_steps_file="playbooks/VMedix/PCR/${_GIT_BRANCH}.txt"
   else
      echo -e "PCR Steps File given      : [${CYN}$pcr_steps_file${NRM}]"
      pcr_steps_file="playbooks/VMedix/PCR/${pcr_steps_file}.txt"
   fi
   echo -e "using the PCR Steps File  : [${CYN}$pcr_steps_file${NRM}]"
   [ ! -e "$pcr_steps_file" ] && { echo -e "${RED}ERROR${NRM}: no such file: $pcr_steps_file"; return; }
   echo -n "setting AWS environment to: "
   sae locapps > /dev/null
   echo -e "[${CYN}$AWSPROF - $AWSENV${NRM}]"
   echo -n "setting Ansible version to: "
   act2.2 > /dev/null
   _ansible_version=$(ansible --version | head -1)
   echo -e "[${CYN}$_ansible_version${NRM}]"
   case "$1" in
      -s) steps_desired=STAGING
          start_line_no=$((`grep -n '^#.*STAGING.*#$' $pcr_steps_file|cut -d: -f1` - 1))
            end_line_no=$((`grep -n '^#.*TESTING/PREPPING.*#$' $pcr_steps_file|cut -d: -f1` - 2)) ;;
      -t) steps_desired=TESTING
          start_line_no=$((`grep -n '^#.*TESTING/PREPPING.*#$' $pcr_steps_file|cut -d: -f1` - 1))
            end_line_no=$((`grep -n '^#.*PRODUCTION.*#$' $pcr_steps_file|cut -d: -f1` - 2)) ;;
      -p) steps_desired=PRODUCTION
          start_line_no=$((`grep -n '^#.*PRODUCTION.*#$' $pcr_steps_file|cut -d: -f1` - 1))
            end_line_no=$((`grep -n '^#.*ROLL-BACK.*#$' $pcr_steps_file|cut -d: -f1` - 2)) ;;
      -r) steps_desired=ROLL-BACK
          start_line_no=$((`grep -n '^#.*ROLL-BACK.*#$' $pcr_steps_file|cut -d: -f1` - 1))
            end_line_no=$((`grep -n '^#.*ROLLBACK COMPLETE.*$' $pcr_steps_file|cut -d: -f1`)) ;;
       *) echo -e "error: invalid argument\n$_USAGE"; return ;;
   esac
   sed -n "${start_line_no},${end_line_no}s/^\$ //p" $pcr_steps_file > $_STEPS
   cp $_STEPS{,.found}
   sed -i "s,\\\!,\\\\\\\!,g" $_STEPS
   if [ -s $_STEPS ]; then
      local _step_no=1
      history -s "vmmopprep $*"
      while read _line; do
         echo "$_line" >> $_STEPS.processed
      done <<< "`cat $_STEPS`"
      echo -n "verifying processed steps : "
      if \diff -q $_STEPS{.found,.processed} > /dev/null; then
         echo -e "[${GRN}PASSED${NRM}]"
         echo -n "adding commands to history: "
         #debug#echo "# BEGIN $steps_desired STEPS"
         history -s "# BEGIN $steps_desired STEPS"
         while read _line; do
            #debug#echo "#$_step_no: $_line"
            echo "$_line" >> $_STEPS.verify
            history -s "#$_step_no: $_line"
            (( _step_no++ ))
         done <<< "`cat $_STEPS`"
         #debug#echo "# END $steps_desired STEPS"
         history -s "# END $steps_desired STEPS"
         echo -e "[${GRN}DONE${NRM}]"
         echo -e "commands added to history : [${MAG}Have fun and good luck!${NRM}]"
      else
         echo -e "[${RED}FAILED${NRM}]"
         echo "NOT adding commands to history"
         echo "differences found:"
         diff $_STEPS{.found,.processed}
      fi
   else
      echo "no commands added to history - could not find any"
   fi
   rm -f $_STEPS{,.found,.processed}
}

function vmprodaccess () {	# VMedix
# add|remove user keys to/from VMedix AWS instances controled via Ansible
   local _USAGE="usage: vmprodaccess us|eu a|1|2|g|b|p [-l apps|data|PATTERN] add|rem USER"
   local _REPO_HOME=~/cloud_automation/ansible
   local _MY_ANS_HOME=~/ansible
   local _cmd
   local _h
   local _pat
   local _user
   local _vpc
   local _country=$1
   if [[ $_country =~ (us|eu) ]]; then
      case $_country in
         us) _vpc=mirkwood          ;;
         eu) _vpc=isengard          ;;
          *) echo "$_USAGE"; return ;;
      esac
   else
      echo "$_USAGE"; return
   fi
   local _hosts=$2
   if [ -n "$_hosts" ]; then
      case $_hosts in
         a) _pat="*${_vpc}*"       ;;
         1) _h=hosts_shared1       ;;
         2) _h=hosts_shared2       ;;
         g) _h=hosts_green         ;;
         b) _h=hosts_blue          ;;
         p) _h=hosts_production    ;;
         *) echo "$_USAGE"; return ;;
      esac
   else
      echo "$_USAGE"; return
   fi
   local _3rd_opt=$3
   if [ "$_3rd_opt" == "-l" ]; then
      local _pattern=$4
      if [ -n "$_pattern" ]; then
         case $_pattern in
            apps) _pat="*ap*" ;;
            data) _pat="mongo*:search*:redis*" ;;
               *) _pat="$_pattern*" ;;
         esac
      else
         echo "$_USAGE"; return
      fi
      _cmd=$5
      _user=$6
   else
      _cmd=$3
      _user=$4
   fi
   if [ -z "$_pat" ]; then
      _pat=all
   fi
   if [ -z "$_cmd" -o -z "$_user" ]; then
      echo "$_USAGE"; return
   fi
   local _ap_cmd="ansible-playbook -i $_REPO_HOME/inventory/VMedix/$_vpc/$_h --limit '$_pat' -e 'c=$_cmd u=$_user' --vault-password-file=~/.vault $_MY_ANS_HOME/playbooks/vm_prod_access.yml"
   eval $_ap_cmd
}

function vmrpms () {	# VMedix
# show RPMs installed on VMedix servers
   local _USAGE="usage: vmrpms us|eu a|g|b|p [PATTERN]"
   local _INV_REPO="~/cloud_automation/ansible/inventory/VMedix"
   local _vpc
   local _h
   local _pat
   local _country=$1
   case $_country in
      us) _vpc="mirkwood";;
      eu) _vpc="isengard";;
       *) echo "$_USAGE"; return;;
   esac
   local _hosts=$2
   case $_hosts in
      a) _pat="*api[0-9]*:*app_nginx[0-9]*";;
      g) _h=hosts_green;;
      b) _h=hosts_blue;;
      p) _h=hosts_production;;
      *) echo "$_USAGE"; return;;
   esac
   local _pattern=$3
   if [ -n "$_pattern" ]; then
      _pat="*$_pattern*"
   else
      _pat="*api[0-9]*:*app_nginx[0-9]*"
   fi
   if [ "$_hosts" == "a" ]; then
      for _h in hosts_blue hosts_green; do
         ansible -T 1 -i $_INV_REPO/$_vpc/$_h "$_pat:!*api_nginx*" --vault-password-file=~/.vault.vm -m shell -a "rpm -qa | grep VirtuMedix" 2>/dev/null | egrep -v 'changed.*false|SSH Error|unreachable.*true|^}' | sed "s/\(^.* UNREACHABLE!\).*$/$(printf "$BLD$RED")\1$(printf "$NRM")/g;s/\(^.* SUCCESS\).*$/$(printf "$BLD$GRN")\1$(printf "$NRM")/g"
      done
   else
      ansible -T 1 -i $_INV_REPO/$_vpc/$_h "$_pat:!*api_nginx*" --vault-password-file=~/.vault.vm -m shell -a "rpm -qa | grep VirtuMedix" 2>/dev/null | egrep -v 'changed.*false|SSH Error|unreachable.*true|^}' | sed "s/\(^.* UNREACHABLE!\).*$/$(printf "$BLD$RED")\1$(printf "$NRM")/g;s/\(^.* SUCCESS\).*$/$(printf "$BLD$GRN")\1$(printf "$NRM")/g"
   fi
}

function wtac () {	# MISC
# what's that AWS command - retrieve the given command for use
   COMMAND_PATTERN="$*"
   COMMANDS_FILE=/home/praco/.aws_commands.txt
   grep "$COMMAND_PATTERN" $COMMANDS_FILE
   while read _line; do
      history -s "$_line"
   done <<< "`grep "$COMMAND_PATTERN" $COMMANDS_FILE`"
}

function wtc () {	# MISC
# what's that command - retrieve the given command for use
   COMMAND_PATTERN="$*"
   COMMANDS_FILE=/home/praco/.commands.txt
   grep "$COMMAND_PATTERN" $COMMANDS_FILE
   while read _line; do
      history -s "$_line"
   done <<< "`grep "$COMMAND_PATTERN" $COMMANDS_FILE`"
}

function wtf () {	# MISC
# what's that file - retrieve the given file for use
   FILE_PATTERN="$*"
   FILES_FILE=/home/praco/.files.txt
   thefile=`grep $FILE_PATTERN $FILES_FILE`
   echo "$thefile"
}

function wutch () {
# like `watch` but colorful
   # couldn't get the trap to work - just remove all - they'll get quickly replaced
   #trap "rm -f $_TMP_WUTCH_OUT; return" SIGINT SIGTERM SIGHUP SIGKILL SIGQUIT
   rm -f /tmp/.wutch.out.*
   local _TMP_WUTCH_OUT=$(mktemp /tmp/.wutch.out.XXX)
   local _secs
   [ "$1" == "-n" ] && { _secs=$2; shift 2; } || _secs=2
   local _cmd="$*"
   local _hcmd="${_cmd:0:35}..."
   clear
   while true; do
      /bin/bash -c "$_cmd" > $_TMP_WUTCH_OUT
      clear
      echo "Every ${_secs}.0s: $_hcmd: `date`"
      echo "Command: '$_cmd'"
      echo "---"
      cat $_TMP_WUTCH_OUT
      tput ed
      sleep $_secs
   done
}

function xsse () {
# ssh in to a server in a seperate xterm window as user: "ec2-user"
   if [ -n "$1" ]; then
      local _server=$1
      $XTERM -e 'eval /usr/bin/ssh -q ec2-user@'"$_server"'' &
   else
      echo "USAGE: xsse HOST"
   fi
}

function xssh () {
# ssh in to a server in a seperate xterm window
   if [ -n "$1" ]; then
      local _server=$1
      $XTERM -e 'eval /usr/bin/ssh -q '"$_server"'' &
   else
      echo "USAGE: xssh HOST"
   fi
}

function zipstuff () {	# MISC
# zip up specified files for backup
   SRCSERVER="praco.dev.local"
   STUFFZIP="/home/praco/stuff.ctcs.zip"
   FILES="
.*rc
.bash*
.csshrc
.aws_commands.txt
.commands.txt
.gitconfig
.gitignore
.files.txt
.ssh/config
.ssh/environment
.tmux.conf
ansible
notes
scripts
"
   # didn't figure out how to make this work
   ##EXCLUDE_FILES="*/.hg/\* repos/.chef/checksums/\* *.zip"
   thisserver=`hostname`
   if [ "$thisserver" = "$SRCSERVER" ]; then
      echo "ziping $FILES to $STUFFZIP... "
      ##/usr/bin/zip -ru $STUFFZIP $FILES -x $EXCLUDE_FILES
      ##/usr/bin/zip -ru $STUFFZIP $FILES -x */.hg/\* repos/.chef/checksums/\* */*/.git/\* */*.zip */*/*.zip
      /usr/bin/zip -ru $STUFFZIP $FILES -x */.hg/\* */.git/\* */*/.git/\* */*.zip */*/*.zip
      echo done
   else
      echo "you have to be on $SRCSERVER to run this"
   fi
}

# set bash prompt command (and bash prompt)
export PROMPT_COMMAND="bash_prompt"
# define aliases
alias ~="cd ~"
alias ..="cd .."
alias -- -="cd -"
#alias a="alias" # use: `sa`
#alias a="alias | cut -d= -f1 | sort | awk -v c=6 'BEGIN{print \"\n\t--- Aliases (use \`sa\` to show details) ---\"}{if(NR%c){printf \"  %-12s\",\$2}else{printf \"  %-12s\n\",\$2}}END{print CR}'"
alias a="alias | cut -d= -f1 | sort | awk -v c=5 'BEGIN{print \"\n\t--- Aliases (use \`sa\` to show details) ---\"}{if(NR%c){printf \"  %-12s\",\$2}else{printf \"  %-12s\n\",\$2}}END{print CR}'"
alias act1='source ~/envs/Ansible_1.x/bin/activate; ansible --version'
alias act2.1='source ~/envs/Ansible_2.x/bin/activate; ansible --version'
alias act2.2='source ~/envs/Ansible_2.2/bin/activate; ansible --version'
alias arcdiff="arc diff --reviewers akulkarni,pfreeman,sbenjamin,tbenichou,tholcomb,candonov main"
alias c="clear"
alias cda="cd ~/cloud_automation/ansible"
alias cdh="cd ~; cd"
alias cdi="cd ~/cloud_automation/ansible/inventory"
alias cdp="cd ~/cloud_automation/ansible/playbooks"
alias cdr="cd ~/cloud_automation/ansible/roles"
alias cols="tsend 'echo \$COLUMNS'"
alias disp="tsend 'echo \$DISPLAY'"
alias cp='cp -i'
alias crt='~/scripts/chef_recipe_tree.sh'
alias cvhf='~/cloud_automation/ansible/playbooks/VMedix/scripts/create_vm_qa_hosts_file.sh'
#alias cssh='cssh -o "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"'
alias diff="colordiff -u"
#alias f="declare -F | awk '{print \$3}' | more"
#alias f="declare -F | awk -v c=4 'BEGIN{print \"\n\t--- Functions (use \`sf\` to show details) ---\"}{if(NR%c){printf \"  %-15s\",\$3}else{printf \"  %-15s\n\",\$3}}END{print CR}'"
alias f="grep '^function .* ' ~/.bash_aliases | awk '{print $2}' | cut -d'(' -f1 | sort | awk -v c=4 'BEGIN{print \"\n\t--- Functions (use \`sf\` to show details) ---\"}{if(NR%c){printf \"  %-18s\",\$2}else{printf \"  %-18s\n\",\$2}}END{print CR}'"
alias fuck='echo "sudo $(history -p \!\!)"; sudo $(history -p \!\!)'
# alias gh="history | grep" # now a function
alias ghwb="sudo dmidecode | egrep -i 'date|bios'"
alias ghwm="sudo dmidecode | egrep -i '^memory device$|	size:.*B'"
alias ghwt='sudo dmidecode | grep "Product Name"'
#alias grep="grep --color=always"
alias grep="grep --color=auto"
alias guid='printf "%x\n" `date +%s`'
alias h="history"
alias kaj='eval kill $(jobs -p)'
alias l.='ls -d .* --color=auto'
alias la='ls -a --color=auto'
alias less="less -FrX"
alias ll='ls -l --color=auto'
alias lla='ls -la --color=auto'
alias ls='ls -CF --color=auto'
alias mv='mv -i'
#alias psa='ps auxfw' # converted to a function
alias myip='curl http://ipecho.net/plain; echo'
alias pa='ps auxfw'
#alias pse='ps -ef' # converted to a function
alias pe='ps -ef'
alias rcrlf="sed 's/$//g' -i.orig"
alias ring="/home/praco/scripts/ring.sh"
alias rsshk='ssh-keygen -f "/home/praco/.ssh/known_hosts" -R'
alias rm='rm -i'
alias sa=alias
alias sba='echo -n "sourcing ~/.bash_aliases... "; source ~/.bash_aliases > /dev/null; echo "done"'
alias sdl="export DISPLAY=localhost:10.0"
alias sf=showf
alias shit='echo "sudo $(history -p \!\!)"; sudo $(history -p \!\!)'
alias sing="/home/praco/scripts/sing.sh"
#alias vagssh='cd ~/cloud_automation/vagrant/CentOS65/; vagrant ssh' # now a function
#alias tt='echo -ne "\e]62;`whoami`@`hostname`\a"'
alias tt='echo -ne "\033]0;`whoami`@`hostname`\007"'
alias tskap="_tmux_send_keys_all_panes"
alias xterm='xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000'
alias u=uptime
alias vba='echo -n "editing ~/.bash_aliases... "; vi ~/.bash_aliases; echo "done"; echo -n "sourcing ~/.bash_aliases... "; source ~/.bash_aliases > /dev/null; echo "done"'
alias vi='`which vim`'
alias view='`which vim` -R'
# alias vms="set | egrep 'CLUST_(NEW|OLD)|HOSTS_(NEW|OLD)|BRNCH_(NEW|OLD)|ES_PD_TSD|SDELEGATE|DB_SCRIPT|VAULT_PWF|VPC_NAME'"
alias which='(alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot'
alias whoa='echo "$(history -p \!\!) | less"; $(history -p \!\!) | less'
