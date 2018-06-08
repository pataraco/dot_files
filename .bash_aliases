#!bash - ~/.bash_aliases - sourced by ~/.bashrc

# -------------------- initial directives --------------------

# if interactive shell - display message
#[ -n "$PS1" ] && echo "sourcing: .bash_aliases"
[ -n "$PS1" ] && echo -n ".bash_aliases (begin)... "

# update change the title bar of the terminal
echo -ne "\033]0;$(whoami)@$(hostname)\007"

# show Ansible, Chef or Python versions in prompt
PS_SHOW_AV=0
PS_SHOW_CV=0
PS_SHOW_PV=0

# -------------------- global variables --------------------

# set company specific variable
export COMPANY="onica"
export COMPANY_SHIT=$HOME/.bash_aliases_$COMPANY

# set environment specific variable
export ENVIRONMENT_SHIT=$HOME/.bash_aliases_chef

# some ansi colorization escape sequences
[ "$(uname)" == "Darwin" ] && ESC="\033" || ESC="\e"
D2E="${ESC}[K"     # to delete the rest of the chars on a line
BLD="${ESC}[1m"    # bold
ULN="${ESC}[4m"    # underlined
BLK="${ESC}[30m"   # black FG
RED="${ESC}[31m"   # red FG
GRN="${ESC}[32m"   # green FG
YLW="${ESC}[33m"   # yellow FG
BLU="${ESC}[34m"   # blue FG
MAG="${ESC}[35m"   # magenta FG
CYN="${ESC}[36m"   # cyan FG
RBG="${ESC}[41m"   # red BG
GBG="${ESC}[42m"   # green BG
YBG="${ESC}[43m"   # yellow BG
BBG="${ESC}[44m"   # blue BG
MBG="${ESC}[45m"   # magenta BG
CBG="${ESC}[46m"   # cyan BG
NRM="${ESC}[m"     # to make text normal

# set xterm defaults
XTERM='xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000'

# set/save original bash prompt
ORIG_PS1=$PS1

# for changing prompt colors
PGRY='\[\e[1;30m\]'   # grey (bold black)
PRED='\[\e[1;31m\]'   # red (bold)
PGRN='\[\e[1;32m\]'   # green (bold)
PYLW='\[\e[1;33m\]'   # yellow (bold)
PBLU='\[\e[1;34m\]'   # blue (bold)
PMAG='\[\e[1;35m\]'   # magenta (bold)
PCYN='\[\e[1;36m\]'   # cyan (bold)
PWHT='\[\e[1;36m\]'   # white (bold)
PNRM='\[\e[m\]'       # to make text normal

# directory where all (most) repos are
REPO_DIR=$HOME/repos

# -------------------- shell settings --------------------

# turn on `vi` command line editing - oh yeah!
set -o vi

# show 3 directories of CWD in prompt
export PROMPT_DIRTRIM=3
# some bind settings
bind Space:magic-space

# # change grep color to light yelow highlighting with black fg
# export GREP_COLOR="5;43;30"
# change grep color to light green fg on black bg
export GREP_COLOR="1;40;32"

# -------------------- define functions --------------------

function _tmux_send_keys_all_panes {
   # send keys to all tmux panes
   for _pane in $(tmux list-panes -F '#P'); do
      tmux send-keys -t ${_pane} "$@" Enter
   done
}

function awsar {
   # list all AWS regions available to me
   aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName
}

function awsdr {
   # AWS Set Default Region
   local _region=$1
   if [ -n "$_region" ]; then
      case $_region in
         uw1)   export AWS_DEFAULT_REGION="us-west-1";;
         uw2)   export AWS_DEFAULT_REGION="us-west-2";;
         ue1)   export AWS_DEFAULT_REGION="us-east-1";;
         ue2)   export AWS_DEFAULT_REGION="us-east-2";;
         ew1)   export AWS_DEFAULT_REGION="eu-west-1";;
         ew2)   export AWS_DEFAULT_REGION="eu-west-2";;
         unset)  unset AWS_DEFAULT_REGION            ;;
         *)     export AWS_DEFAULT_REGION="$_region" ;;
      esac
   else
      echo "AWS_DEFAULT_REGION    = ${AWS_DEFAULT_REGION:-N/A}"
   fi
}

function awssnsep {
   # AWS SNS list platform application endpoints
   local _USAGE="usage: awssnsep APPLICATION [REGION]  # can use 'all'"
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

function awsasgcp {
   # usage:
   #   awsasgcp 
   #     -r|--resume or -s|--suspend
   #     [--region REGION] [--dry-run] [AutoScalingGroupName|RegEx]
   # suspend/resume ALL AWS AutoScaling processes
   # optional: AutoScalingGroupName or RegEx
   #   only for a specified autoscaling group name or those matching a reg-ex
   # defaults to "running" (i.e. run the command)
   #   must use "--dry-run" option to NOT perform
   local _USAGE="usage: awsasgcp -r|--resume or -s|--suspend [--region REGION] [--dry-run] [AutoScalingGroupName|RegEx]"
   local _AWS_CMD=$(/usr/bin/which aws 2> /dev/null) || { echo "'aws' needed to run this function"; exit 3; }
   local _JQ_CMD=$(/usr/bin/which jq 2> /dev/null) || { echo "'jq' needed to run this function"; exit 3; }
   local _dryrun=running
   local _pc_cmd
   local _region
   while true; do
      case "$1" in
          -r|--resume) _pc_cmd=resume-processes ; shift;;
         -s|--suspend) _pc_cmd=suspend-processes; shift;;
            --dry-run) _dryrun=dry-run          ; shift;;
             --region) _region="--region $2"    ; shift 2;;
                    *) break;;
      esac
   done
   [ -z "$_pc_cmd" ] && { echo "$_USAGE"; return; }
   local _asgn_pattern=$*
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

function awsci {
   # reboot, start, stop or terminate an instance
   local _AWS_CMD=$(which aws)
   [ -z "$_AWS_CMD" ] && { echo "error: aws command not found"; return 2; }
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _USAGE="usage: awsci [-r REGION] reboot|start|stop|terminate INSTANCE_ID|INSTANCE_NAME   # default region: $_DEFAULT_REGION"
   local _region=$1
   [ "$_region" == "-r" ] && { _region=$2; shift 2; } || _region=$_DEFAULT_REGION
   local _CONTROL_CMD=$1
   local _INSTANCE_PATTERN=$2
   [ -z "$_CONTROL_CMD" ] && { echo "error: did not specify 'reboot', 'start', 'stop' or 'terminate'"; echo "$_USAGE"; return; }
   [ -z "$_INSTANCE_PATTERN" ] && { echo "error: did not specify an instance name or ID"; echo "$_USAGE"; return; }
   local _instance_id
   local _instance_name
   _instance_name=$($_AWS_CMD ec2 describe-instances --region $_region --instance-ids $_INSTANCE_PATTERN --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value]" --output text 2> /dev/null)
   if [ $? -eq 0 ]; then
      _instance_id=$_INSTANCE_PATTERN
   else
      _instance_id=$($_AWS_CMD ec2 describe-instances --region $_region --filters "Name=tag:Name,Values=*${_INSTANCE_PATTERN}*" --output json | jq -r .Reservations[].Instances[].InstanceId 2> /dev/null)
      _instance_name=$($_AWS_CMD ec2 describe-instances --region $_region --instance-ids $_instance_id --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value]" --output text 2> /dev/null)
   fi
   [ -z "$_instance_name" ] && { echo "note: did not find an instance with ID: $_instance_id"; return; }
   [ -z "$_instance_id" ] && { echo "note: did not find instance named: $_instance_name"; return; }
   local _no_of_ids=$(echo "$_instance_id" | wc -l)
   [ $_no_of_ids -gt 1 ] && { echo "note: found more than one instance - please be more specific"; return; }
   local _instance_state=$($_AWS_CMD ec2 describe-instances --region $_region --instance-ids $_instance_id --query "Reservations[].Instances[].State.Name" --output text)
   local _aws_ec2_cmd
   case $_CONTROL_CMD in
      reboot)
         [ "$_instance_state" != "running" ] && { echo "$_instance_name ($_instance_id) is NOT running"; return; }
         _aws_ec2_cmd=reboot-instances ;;
      start)
         [ "$_instance_state" == "running" ] && { echo "$_instance_name ($_instance_id) is already running"; return; }
         _aws_ec2_cmd=start-instances ;;
      stop)
         [ "$_instance_state" == "stopped" ] && { echo "$_instance_name ($_instance_id) is already stopped"; return; }
         _aws_ec2_cmd=stop-instances  ;;
      terminate)
         _aws_ec2_cmd=terminate-instances ;;
      *)
         echo "unknown option: exiting..."; echo "$_USAGE"; return;;
   esac
   local _ans
   echo "Instance: $_instance_name ($_instance_id) is $_instance_state"
   #read -p "Are you sure that you want to ${_CONTROL_CMD^^} it [yes/no]? " _ans
   read -p "Are you sure that you want to '${_CONTROL_CMD}' it [yes/no]? " _ans
   if [ "$_ans" == "yes" -o "$_ans" == "YES" ]; then
      $_AWS_CMD ec2 $_aws_ec2_cmd --region $_region --instance-ids $_instance_id
   else
      echo "Did not enter 'yes'; NOT going to ${_CONTROL_CMD} the instance"
   fi
}

function awsdami {
   # some 'aws ec2 describe-images' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWSEC2DAMI_CMD="aws ec2 describe-images"
   local _USAGE="usage: \
awsdami [OPTIONS]
  -a  ARCH      # Architecture (e.g. i386, x86_64)
  -ht HYPE_TYPE # Hypervisor Type (e.g. ovm, xen)
  -i  ID        # Image ID (RegEx)
  -it IMG_TYPE  # Image Type (e.g. machine, kernel, ramdisk)
  -n  NAME      # Image Name (RegEx)
  -o  OWNERS    # Owners (e.g. amazon, aws-marketplace, AWS ID. default: self)
  -p  PROJECT   # Project
  -r  REGION    # Region to query (default: $_DEFAULT_REGION, 'all' for all)
  -s  STATE     # State
  -v  VIRT_TYPE # Virtualization Type (e.g. paravirtual, hvm)
  -vs VOL_SIZE  # Volume Size (in GiB)
  -vt VOL_TYPE  # Volume Type (e.g. gp2, io1, st1, sc1, standard)
  +a            # show Architecture
  +cc           # show Charge Code
  +cd           # show Creation Date
  +ht           # show Hypervisor Type
  +i            # show Image ID
  +it           # show Image Type
  +o            # show Owner ID
  +p            # show Project
  +ps           # show Public Status
  +rn           # show Root Device Name
  +rt           # show Root Device Type
  +s            # show State
  +v            # show Virtualization Type
  +vs           # show Volume Size
  +vt           # show Volume Type
  -h            # help (show this message)
default display:
  Image Name | Image ID | State"
   local _owners="self"
   local _region="$_DEFAULT_REGION"
   local _filters=""
   local _queries="Tags[?Key=='Name'].Value|[0]"
   local _default_queries="Tags[?Key=='Name'].Value|[0],ImageId,State"
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
          +a) _more_qs="$_more_qs${_more_qs:+,}Architecture"                                     ; shift;;
         +cc) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='ChargeCode'].Value|[0]"               ; shift;;
         +cd) _more_qs="$_more_qs${_more_qs:+,}CreationDate"                                     ; shift;;
         +ht) _more_qs="$_more_qs${_more_qs:+,}Hypervisor"                                       ; shift;;
          +i) _more_qs="$_more_qs${_more_qs:+,}ImageId"                                          ; shift;;
         +it) _more_qs="$_more_qs${_more_qs:+,}ImageType"                                        ; shift;;
          +o) _more_qs="$_more_qs${_more_qs:+,}OwnerId"                                          ; shift;;
          +p) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Project'].Value|[0]"                  ; shift;;
         +ps) _more_qs="$_more_qs${_more_qs:+,}Public"                                           ; shift;;
         +rn) _more_qs="$_more_qs${_more_qs:+,}RootDeviceName"                                   ; shift;;
         +rt) _more_qs="$_more_qs${_more_qs:+,}RootDeviceType"                                   ; shift;;
          +s) _more_qs="$_more_qs${_more_qs:+,}State"                                            ; shift;;
          +v) _more_qs="$_more_qs${_more_qs:+,}VirtualizationType"                               ; shift;;
         +vs) _more_qs="$_more_qs${_more_qs:+,}BlockDeviceMappings[0].Ebs.VolumeSize"            ; shift;;
         +vt) _more_qs="$_more_qs${_more_qs:+,}BlockDeviceMappings[0].Ebs.VolumeType"            ; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         #$_AWSEC2DAMI_CMD --region=$_region --owners $_owners $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeImages' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         $_AWSEC2DAMI_CMD --region=$_region --owners $_owners $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeImages' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_AWSEC2DAMI_CMD --region=$_region --owners $_owners $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeImages' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsdasg {
   # some 'aws autoscaling describe-auto-scaling-groups' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWSASDASG_CMD="aws autoscaling describe-auto-scaling-groups"
   local _USAGE="usage: \
awsdasg [OPTIONS]
  -n NAME      # filter results by this Auto Scaling Group Name
  -m MAX       # maximum number of items to display
  -r REGION    # region to query (default: $_DEFAULT_REGION, 'all' for all)
  +bt          # show Branch Tag
  +c           # show Cluster
  +cc          # show Charge Code
  +dc          # show Desired Capacity
  +e           # show Env (Environment)
  +ht          # show Health Check Type
  +ii          # show Instance Id(s)
  +ih          # show Instance Health Status
  +lb          # show Load Balancers
  +lc          # show Launch Configuration Name
  +ls          # show Life Cycle State
  +mr          # show Machine Role
  +ni          # show Number of Instances
  +ns          # show Min Size
  +xs          # show Max Size
  +p           # show Project
  +sp          # show Suspended Processes
  +v           # show VPC Name
  -h           # help (show this message)
default display:
  ASG name | Launch Config Name | Instances | Desired | Min | Max | Region"
   local _max_items=""
   local _region="$_DEFAULT_REGION"
   local _reg_exp=""
   local _queries="AutoScalingGroupName"
   local _default_queries="AutoScalingGroupName,LaunchConfigurationName,length(Instances),DesiredCapacity,MinSize,MaxSize"
   local _more_qs=""
   local _query="AutoScalingGroups[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -n) _reg_exp="$2"              ; shift 2;;
          -m) _max_items="--max-items $2"; shift 2;;
          -r) _region=$2                 ; shift 2;;
         +bt) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='BranchTag'].Value|[0]"            ; shift;;
          +c) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Cluster'].Value|[0]"              ; shift;;
         +cc) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='ChargeCode'].Value|[0]"           ; shift;;
         +dc) _more_qs="$_more_qs${_more_qs:+,}DesiredCapacity"                              ; shift;;
          +e) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Env'].Value|[0]"                  ; shift;;
         +ht) _more_qs="$_more_qs${_more_qs:+,}HealthCheckType"                              ; shift;;
         +ii) _more_qs="$_more_qs${_more_qs:+,}Instances[].InstanceId|join(', ',@)"          ; shift;;
         +ih) _more_qs="$_more_qs${_more_qs:+,}Instances[].HealthStatus|join(', ',@)"        ; shift;;
         +lb) _more_qs="$_more_qs${_more_qs:+,}LoadBalancerNames[]|join(', ',@)"             ; shift;;
         +lc) _more_qs="$_more_qs${_more_qs:+,}LaunchConfigurationName"                      ; shift;;
         +ls) _more_qs="$_more_qs${_more_qs:+,}Instances[].LifecycleState|join(', ',@)"      ; shift;;
         +mr) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='MachineRole'].Value|[0]"          ; shift;;
         +ni) _more_qs="$_more_qs${_more_qs:+,}length(Instances)"                            ; shift;;
         +ns) _more_qs="$_more_qs${_more_qs:+,}MinSize"                                      ; shift;;
         +xs) _more_qs="$_more_qs${_more_qs:+,}MaxSize"                                      ; shift;;
          +p) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Project'].Value|[0]"              ; shift;;
         +sp) _more_qs="$_more_qs${_more_qs:+,}SuspendedProcesses[].ProcessName|join(', ',@)"; shift;;
          +v) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='VPCName'].Value|[0]"              ; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         if [ -z "$_reg_exp" ]; then
            $_AWSASDASG_CMD --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeAutoScalingGroups' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         else
            $_AWSASDASG_CMD --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         fi
      done
   else
      if [ -z "$_reg_exp" ]; then
         $_AWSASDASG_CMD --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeAutoScalingGroups' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      else
         $_AWSASDASG_CMD --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      fi
   fi
}

function awsdi {
   # some 'aws ec2 describe-instances' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWS_EC2_DI_CMD="aws ec2 describe-instances"
   local _USAGE="usage: \
awsdi [OPTIONS]
  -e  ENVIRON  # filter results by this Environment (e.g. production, staging)
  -n  NAME     # filter results by this Instance Name
  -pj PROJECT  # filter results by this Project
  -s  STATE    # filter results by this State (e.g. running, terminated, etc.)
  -t  KEY=VAL  # filter results by this tag (key=val)
  -m  MAX      # maximum number of items to display
  -r  REGION   # Region to query (default: $_DEFAULT_REGION, 'all' for all)
  +a           # show AMI (ImageId)
  +an          # show ASG Name
  +az          # show Availability Zone
  +bt          # show Branch Tag
  +c           # show Cluster
  +cc          # show Charge Code
  +e           # show Env (Environment)
  +i           # show Private IP
  +it          # show Instance Type
  +k           # show Key Pair name
  +lt          # show Launch Time
  +mr          # show Machine Role
  +p           # show Platform
  +pj          # show Project
  +pi          # show Public IP
  +pt          # show Placment Tenancy
  +s           # show State (e.g. running, stopped...)
  +si          # show Security Group Id(s)
  +sn          # show Security Group Name(s)
  +t KEY       # show tag (KEY)
  +v           # show VPC ID
  +vn          # show VPC Name (tag: VPCName)
  -h           # help (show this message)
default display:
  Inst name | Private IP | Instance ID | State"
   local _max_items=""
   local _region="$_DEFAULT_REGION"
   local _filters=""
   local _queries="Tags[?Key=='Name'].Value|[0],InstanceId"
   local _default_queries="Tags[?Key=='Name'].Value|[0],InstanceId,PrivateIpAddress,State.Name"
   local _more_qs=""
   local _query="Reservations[].Instances[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -e) _filters="Name=tag:Env,Values=*$2* $_filters"            ; shift 2;;
          -n) _filters="Name=tag:Name,Values=*$2* $_filters"           ; shift 2;;
         -pj) _filters="Name=tag:Project,Values=*$2* $_filters"        ; shift 2;;
          -s) _filters="Name=instance-state-name,Values=*$2* $_filters"; shift 2;;
          -t) _filters="Name=tag:${2%%=*},Values=*${2##*=}* $_filters" ; shift 2;;
          -m) _max_items="--max-items $2"                              ; shift 2;;
          -r) _region=$2                                               ; shift 2;;
          +a) _more_qs="$_more_qs${_more_qs:+,}ImageId"                                          ; shift;;
         +an) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='aws:autoscaling:groupName'].Value|[0]"; shift;;
         +az) _more_qs="$_more_qs${_more_qs:+,}Placement.AvailabilityZone"                       ; shift;;
         +bt) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='BranchTag'].Value|[0]"                ; shift;;
          +c) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Cluster'].Value|[0]"                  ; shift;;
         +cc) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='ChargeCode'].Value|[0]"               ; shift;;
          +e) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Env'].Value|[0]"                      ; shift;;
          +i) _more_qs="$_more_qs${_more_qs:+,}PrivateIpAddress"                                 ; shift;;
         +it) _more_qs="$_more_qs${_more_qs:+,}InstanceType"                                     ; shift;;
          +k) _more_qs="$_more_qs${_more_qs:+,}KeyName"                                          ; shift;;
         +lt) _more_qs="$_more_qs${_more_qs:+,}LaunchTime"                                       ; shift;;
         +mr) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Role'].Value|[0]"                     ; shift;;
          +p) _more_qs="$_more_qs${_more_qs:+,}Platform"                                         ; shift;;
         +pj) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='Project'].Value|[0]"                  ; shift;;
         +pi) _more_qs="$_more_qs${_more_qs:+,}PublicIpAddress"                                  ; shift;;
         +pt) _more_qs="$_more_qs${_more_qs:+,}Placement.Tenancy"                                ; shift;;
          +s) _more_qs="$_more_qs${_more_qs:+,}State.Name"                                       ; shift;;
         +si) _more_qs="$_more_qs${_more_qs:+,}SecurityGroups[].GroupId|join(', ',@)"            ; shift;;
         +sn) _more_qs="$_more_qs${_more_qs:+,}SecurityGroups[].GroupName|join(', ',@)"          ; shift;;
          +t) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='$2'].Value|[0]"                       ; shift 2;;
          +v) _more_qs="$_more_qs${_more_qs:+,}VpcId"                                            ; shift;;
         +vn) _more_qs="$_more_qs${_more_qs:+,}Tags[?Key=='VPCName'].Value|[0]"                  ; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         #$_AWS_EC2_DI_CMD --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         $_AWS_EC2_DI_CMD --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      #debug# echo "$_AWS_EC2_DI_CMD --region=$_region $_max_items $_filters --query \"$_query\" --output table"
      $_AWS_EC2_DI_CMD --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstances' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsdis {
   # some 'aws ec2 describe-instance-status' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWS_EC2_DIS_CMD="aws ec2 describe-instance-status"
   local _USAGE="usage: \
awsdis [OPTIONS]
  -c  CODE       # filter by Event Code ({instance,system}-{reboot,retirement,stop,maintenance})
  -s  STATE      # filter by Instance State (pending, running, shutting-down, terminated, stopped)
  -r  REGION     # Region to query (default: $_DEFAULT_REGION, 'all' for all)
  +az            # show Availability Zone
  +c             # show Events Codes
  +d             # show Events Descriptions
  +s             # show Instance State
  +t             # show Events Dates and Times
  -h             # help (show this message)
default display:
  Instance ID | State | Event Code | Event Description"
   local _region="$_DEFAULT_REGION"
   local _filters=""
   local _queries="InstanceId"
   #local _default_queries="InstanceId,InstanceState.Name,Events[].Code|join(', ',@),Events[].Description|join(', ',@)"
   local _default_queries="InstanceId,InstanceState.Name,Events[0].Code,Events[0].Description"
   local _more_qs=""
   local _query="InstanceStatuses[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -c) _filters="Name=event.code,Values=*$2* $_filters"      ; shift 2;;
          -s) _filters="Name=instance-state-name,Values=*$2* $_filters"      ; shift 2;;
          -r) _region=$2                                               ; shift 2;;
         +az) _more_qs="$_more_qs${_more_qs:+,}AVailabilityZone"      ; shift;;
          #+c) _more_qs="$_more_qs${_more_qs:+,}Events[].Code|join(', ',@)"      ; shift;;
          +c) _more_qs="$_more_qs${_more_qs:+,}Events[0].Code"      ; shift;;
          #+d) _more_qs="$_more_qs${_more_qs:+,}Events[].Description|join(', ',@)"      ; shift;;
          +d) _more_qs="$_more_qs${_more_qs:+,}Events[0].Description"      ; shift;;
          +s) _more_qs="$_more_qs${_more_qs:+,}InstanceState.Name"      ; shift;;
          #+t) _more_qs="$_more_qs${_more_qs:+,}Events[].NotBefore|join(', ',@),Events[].NotAfter|join(', ',@)"      ; shift;;
          +t) _more_qs="$_more_qs${_more_qs:+,}Events[0].NotBefore,Events[0].NotAfter"      ; shift;;
         #+fp) _more_qs="$_more_qs${_more_qs:+,}IpPermissions[].FromPort|join(', ',to_array(to_string(@)))"; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         #$_AWS_EC2_DIS_CMD --region=$_region $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstanceStatus' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         $_AWS_EC2_DIS_CMD --region=$_region $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstanceStatus' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_AWS_EC2_DIS_CMD --region=$_region $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeInstanceStatus' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsdlb {
   # some 'aws elb describe-load-balancer' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWSELBDLB_CMD="aws elb describe-load-balancers"
   local _USAGE="usage: \
awsdlb [OPTIONS]
  -n NAME      # filter results by this Launch Config Name
  -m MAX       # the maximum number of items to display
  -r REGION    # Region to query (default: $_DEFAULT_REGION, 'all' for all)
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
   local _max_items=""
   local _region="$_DEFAULT_REGION"
   local _reg_exp=""
   local _queries="LoadBalancerName"
   local _default_queries="LoadBalancerName"
   local _more_qs=""
   local _query="LoadBalancerDescriptions[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -n) _reg_exp="$2"              ; shift 2;;
          -m) _max_items="--max-items $2"; shift 2;;
          -r) _region=$2                 ; shift 2;;
         +az) _more_qs="$_more_qs${_more_qs:+,}AvailabilityZones[]|join(', '@)"   ; shift;;
          +d) _more_qs="$_more_qs${_more_qs:+,}DNSName"                           ; shift;;
          +i) _more_qs="$_more_qs${_more_qs:+,}Instances[].InstanceId|join(', '@)"; shift;;
          +s) _more_qs="$_more_qs${_more_qs:+,}Scheme"                            ; shift;;
         +sg) _more_qs="$_more_qs${_more_qs:+,}SecurityGroups|join(', ',@)"       ; shift;;
         +sn) _more_qs="$_more_qs${_more_qs:+,}Subnets[]|join(', '@)"             ; shift;;
         +hc) _more_qs="$_more_qs${_more_qs:+,}HealthCheck.HealthyThreshold,HealthCheck.Interval,HealthCheck.Target,HealthCheck.Timeout,HealthCheck.UnhealthyThreshold"; shift;;
         +li) _more_qs="$_more_qs${_more_qs:+,}ListenerDescriptions[0].Listener.LoadBalancerPort,ListenerDescriptions[0].Listener.Protocol,ListenerDescriptions[0].Listener.InstancePort,ListenerDescriptions[0].Listener.InstanceProtocol"; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         if [ -z "$_reg_exp" ]; then
            $_AWSELBDLB_CMD --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLoadBalancers' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         else
            $_AWSELBDLB_CMD --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         fi
      done
   else
      if [ -z "$_reg_exp" ]; then
         $_AWSELBDLB_CMD --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLoadBalancers' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      else
         $_AWSELBDLB_CMD --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      fi
   fi
}

function awsdlc {
   # some 'aws autoscaling describe-launch-configurations' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWSASDLC_CMD="aws autoscaling describe-launch-configurations"
   local _USAGE="usage: \
awsdlc [OPTIONS]
  -n NAME      # filter results by this Launch Config Name
  -m MAX       # the maximum number of items to display
  -r REGION    # Region to query (default: $_DEFAULT_REGION, 'all' for all)
  +i           # show Image ID
  +ip          # show IAM Instance Profile
  +it          # show Instance Type
  +kn          # show Key Name
  +pt          # show Placement Tenancy
  +sg          # show Security Groups
  -h           # help (show this message)
default display:
  Launch Config name | AMI ID | Instance Type | Region"
   local _max_items=""
   local _region="$_DEFAULT_REGION"
   local _reg_exp=""
   local _queries="LaunchConfigurationName"
   local _default_queries="LaunchConfigurationName,ImageId,InstanceType"
   local _more_qs=""
   local _query="LaunchConfigurations[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -n) _reg_exp="$2"              ; shift 2;;
          -m) _max_items="--max-items $2"; shift 2;;
          -r) _region=$2                 ; shift 2;;
          +i) _more_qs="$_more_qs${_more_qs:+,}ImageId"                    ; shift;;
         +ip) _more_qs="$_more_qs${_more_qs:+,}IamInstanceProfile"         ; shift;;
         +it) _more_qs="$_more_qs${_more_qs:+,}InstanceType"               ; shift;;
         +kn) _more_qs="$_more_qs${_more_qs:+,}KeyName"                    ; shift;;
         +pt) _more_qs="$_more_qs${_more_qs:+,}PlacementTenancy"           ; shift;;
         +sg) _more_qs="$_more_qs${_more_qs:+,}SecurityGroups|join(', ',@)"; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         if [ -z "$_reg_exp" ]; then
            $_AWSASDLC_CMD --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLaunchConfigurations' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         else
            $_AWSASDLC_CMD --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         fi
      done
   else
      if [ -z "$_reg_exp" ]; then
         $_AWSASDLC_CMD --region=$_region $_max_items --query "$_query" --output table | egrep -v '^[-+]|DescribeLaunchConfigurations' | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      else
         $_AWSASDLC_CMD --region=$_region $_max_items --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      fi
   fi
}

function awsdni {
   # some 'aws ec2 describe-network-interfaces' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWSEC2DNI_CMD="aws ec2 describe-network-interfaces"
   local _USAGE="usage: \
awsdni [OPTIONS]
  -a  AZ       # filter by Availability Zone (RegEx)
  -d  DESC     # filter by Description
  -i  IP_PRIV  # filter by Private IP
  -id ID       # filter by Interface ID
  -p  IP_PUB   # filter by Public IP
  -r  REGION   # region to query (default: $_DEFAULT_REGION, 'all' for all)
  -s  STATUS   # filter by Status (e.g. in-use, etc.)
  +az          # show Availability Zone
  +d           # show Description
  +m           # show MAC Address
  +p           # show Public IP
  +pi          # show Private IP
  +s           # show Status
  +sd          # show Subnet ID
  +si          # show Security Group Id(s)
  +sn          # show Security Group Name(s)
  +v           # show VPC ID
  -h           # help (show this message)
default display:
  ID | Description | Private IP | Status"
   local _max_items=""
   local _region="$_DEFAULT_REGION"
   local _filters=""
   local _queries="NetworkInterfaceId"
   local _default_queries="NetworkInterfaceId,Description,PrivateIpAddress,Status"
   local _more_qs=""
   local _query="NetworkInterfaces[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -a) _filters="Name=availability-zone,Values=*$2* $_filters"           ; shift 2;;
          -d) _filters="Name=description,Values=*$2* $_filters"                 ; shift 2;;
          -i) _filters="Name=addresses.private-ip-address,Values=*$2* $_filters"; shift 2;;
         -id) _filters="Name=network-interface-id,Values=*$2* $_filters"        ; shift 2;;
          -p) _filters="Name=association.public-ip,Values=*$2* $_filters"       ; shift 2;;
          -r) _region=$2                                                        ; shift 2;;
          -s) _filters="Name=status,Values=*$2* $_filters"                      ; shift 2;;
         +ai) _more_qs="$_more_qs${_more_qs:+,}PrivateIpAddresses[].PrivateIpAddress|join(', ',@)"; shift;;
         +az) _more_qs="$_more_qs${_more_qs:+,}AvailabilityZone"                                  ; shift;;
          +d) _more_qs="$_more_qs${_more_qs:+,}Description"                                       ; shift;;
          +m) _more_qs="$_more_qs${_more_qs:+,}MacAddress"                                        ; shift;;
          +p) _more_qs="$_more_qs${_more_qs:+,}PrivateIpAddress"                                  ; shift;;
         +pi) _more_qs="$_more_qs${_more_qs:+,}Association.PublicIp"                              ; shift;;
          +s) _more_qs="$_more_qs${_more_qs:+,}Status"                                            ; shift;;
         +sd) _more_qs="$_more_qs${_more_qs:+,}SubnetId"                                          ; shift;;
         +si) _more_qs="$_more_qs${_more_qs:+,}Groups[].GroupId|join(', ',@)"                     ; shift;;
         +sn) _more_qs="$_more_qs${_more_qs:+,}Groups[].GroupName|join(', ',@)"                   ; shift;;
          +v) _more_qs="$_more_qs${_more_qs:+,}VpcId"                                             ; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         $_AWSEC2DNI_CMD --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeNetworkInterfaces' | sort | sed 's/^| *//;s/ *| */|/g;s/ *|$/|'"$_region"'/' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_AWSEC2DNI_CMD --region=$_region $_max_items $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeNetworkInterfaces' | sort | sed 's/^| *//;s/ *| */|/g;s/ *|$//g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsdsg {
   # some 'aws ec2 describe-security-groups' hacks
   local _ALL_REGIONS=$(aws ec2 describe-regions --region us-east-1 | jq -r .Regions[].RegionName)
   local _DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-west-2}"
   local _AWS_EC2_DSG_CMD="aws ec2 describe-security-groups"
   local _USAGE="usage: \
awsdsg [OPTIONS]
  -p  PROJECT    # filter results by this Project
  -e  ENVIRONMNT # filter results by this Environment (e.g. production, staging)
  -i  GROUP_ID   # filter results by this SG ID
  -n  SG_NAME    # filter results by this SG Name
  -c  CIDR       # filter results by this CIDR (Ingress)
  -v  VPC_ID     # filter results by this VPC ID
  -gi SG_ID      # filter results by this SG ID that has been granted permission
  -gn SG_NAME    # filter results by this SG Name that has been granted permission
  -fp FROM_PORT  # filter results by this starting port number
  -tp TO_PORT    # filter results by this ending port number
  -pp PROTOCOL   # filter results by this Protocol
  -r  REGION     # Region to query (default: $_DEFAULT_REGION, 'all' for all)
  +e             # show Egress
  +i             # show Igress
  +fp            # show From Ports
  +tp            # show To Ports
  +pp            # show Protocols
  -h             # help (show this message)
default display:
  SG ID | SG Name | VPC ID | Description"
   local _region="$_DEFAULT_REGION"
   local _filters=""
   local _queries="GroupId"
   local _default_queries="GroupId,GroupName,VpcId,Description"
   local _more_qs=""
   local _query="SecurityGroups[]"
   while [ $# -gt 0 ]; do
      case $1 in
          -p) _filters="Name=tag:Project,Values=*$2* $_filters"             ; shift 2;;
          -e) _filters="Name=tag:Env,Values=*$2* $_filters"                 ; shift 2;;
          -i) _filters="Name=group-id,Values=*$2* $_filters"                ; shift 2;;
          -c) _filters="Name=ip-permission.cidr,Values=*$2* $_filters"      ; shift 2;;
         -gi) _filters="Name=ip-permission.group-id,Values=*$2* $_filters"  ; shift 2;;
         -gn) _filters="Name=ip-permission.group-name,Values=*$2* $_filters"; shift 2;;
         -fp) _filters="Name=ip-permission.from-port,Values=*$2* $_filters" ; shift 2;;
         -tp) _filters="Name=ip-permission.to-port,Values=*$2* $_filters"   ; shift 2;;
         -pp) _filters="Name=ip-permission.protocol,Values=*$2* $_filters"  ; shift 2;;
          -n) _filters="Name=group-name,Values=*$2* $_filters"              ; shift 2;;
          -v) _filters="Name=vpc-id,Values=*$2* $_filters"                  ; shift 2;;
          -r) _region=$2                                                    ; shift 2;;
          +e) _more_qs="$_more_qs${_more_qs:+,}IpPermissionsEgress[].IpRanges[].CidrIp|join(', ',@)"      ; shift;;
          +i) _more_qs="$_more_qs${_more_qs:+,}IpPermissions[].IpRanges[].CidrIp|join(', ',@)"            ; shift;;
         +fp) _more_qs="$_more_qs${_more_qs:+,}IpPermissions[].FromPort|join(', ',to_array(to_string(@)))"; shift;;
         +tp) _more_qs="$_more_qs${_more_qs:+,}IpPermissions[].ToPort|join(', ',to_array(to_string(@)))"  ; shift;;
         +pp) _more_qs="$_more_qs${_more_qs:+,}IpPermissions[].IpProtocol|join(',',@)"                    ; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -n "$_filters" ] && _filters="--filters ${_filters% }"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   if [ "$_region" == "all" ]; then
      for _region in $_ALL_REGIONS; do
         #$_AWS_EC2_DSG_CMD --region=$_region $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeSecurityGroups' | sort | sed 's/^| //;s/ \+|$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
         $_AWS_EC2_DSG_CMD --region=$_region $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeSecurityGroups' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
      done
   else
      $_AWS_EC2_DSG_CMD --region=$_region $_filters --query "$_query" --output table | egrep -v '^[-+]|DescribeSecurityGroups' | sort | sed 's/^| //;s/ \+|$//;s/ |$/|'"$_region"'/;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function awsrlrrs {
   # some 'aws route53 list-resource-record-sets' hacks
   local _AWSRLRRS_CMD="aws route53 list-resource-record-sets"
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
   local _max_items=""
   local _rec_type="*"
   local _queries="Name,Type,ResourceRecords[].Value|[0]"
   local _default_queries="Name,Type,ResourceRecords[].Value|[0]"
   local _reg_exp=""
   local _more_qs=""
   while [ $# -gt 0 ]; do
      case $1 in
          -d) _dns_name="$2"             ; shift 2;;
          -m) _max_items="--max-items $2"; shift 2;;
          -n) _reg_exp="$2"              ; shift 2;;
          -t) _rec_type="?Type=='$2'"    ; shift 2;;
          +s) _more_qs="$_more_qs${_more_qs:+,}SetIdentifier"; shift;;
          +t) _more_qs="$_more_qs${_more_qs:+,}TTL"          ; shift;;
          +w) _more_qs="$_more_qs${_more_qs:+,}Weight"       ; shift;;
        -h|*) echo "$_USAGE"; return;;
      esac
   done
   [ -z "$_dns_name" ] && { echo "error: did not specify DNS_NAME"; echo "$_USAGE"; return; }
   local _query="ResourceRecordSets[$_rec_type]"
   [ -n "$_more_qs" ] && _query="$_query.[$_queries,${_more_qs%,}]" || _query="$_query.[$_default_queries]"
   # get the Hosted Zone Id
   hosted_zone_id=$(aws route53 list-hosted-zones-by-name --dns-name $_dns_name --max-items 1 | jq -r .HostedZones[].Id)
   if [ -z "$_reg_exp" ]; then
      $_AWSRLRRS_CMD --hosted-zone-id $hosted_zone_id --query "$_query" --output table | egrep -v '^[-+]|ListResourceRecordSets' | sort | sed 's/^| //;s/ |$//g;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   else
      $_AWSRLRRS_CMD --hosted-zone-id $hosted_zone_id --query "$_query" --output table | grep "$_reg_exp" | sort | sed 's/^| //;s/ |$//g;s/ //g' | column -s'|' -t | sed 's/\(  \)\([a-zA-Z0-9]\)/ | \2/g'
   fi
}

function bash_prompt {
   # customize Bash Prompt
   local _versions_len=0
   if [ $PS_SHOW_CV -eq 1 ]; then
      # get Chef version
      if [ -z "$CHEF_VERSION" ]; then
         export CHEF_VERSION=$(knife --version 2>/dev/null | head -1 | awk '{print $NF}')
      fi
      PS_CHF="${PYLW}C$CHEF_VERSION$PNRM"
      (( _versions_len += ${#CHEF_VERSION} + 1 ))
   fi
   if [ $PS_SHOW_AV -eq 1 ]; then
   # get Ansible version
      if [ -z "$ANSIBLE_VERSION" ]; then
         export ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1 | awk '{print $NF}')
      fi
      PS_ANS="${PCYN}A$ANSIBLE_VERSION$PNRM"
      (( _versions_len += ${#ANSIBLE_VERSION} + 1 ))
   fi
   if [ $PS_SHOW_PV -eq 1 ]; then
      # get Python version
      if [ -z "$PYTHON_VERSION" ]; then
         export PYTHON_VERSION=$(python --version 2>&1 | awk '{print $NF}')
      fi
      PS_PY="${PMAG}P$PYTHON_VERSION$PNRM"
      (( _versions_len += ${#PYTHON_VERSION} + 1 ))
   fi
   # get git info
   git branch &> /dev/null
   if [ $? -eq 0 ]; then   # in a git repo
      #local _git_branch=$(git branch 2>/dev/null|grep '^*'|colrm 1 2)
      local _git_branch=$(git branch 2>/dev/null|grep '^*'|awk '{print $NF}')
      local _git_branch_len=$(( ${#_git_branch} + 1 ))
      local _git_status=$(git status --porcelain 2> /dev/null)
      [[ $_git_status =~ ($'\n'|^).M ]] && local _git_has_mods=true
      [[ $_git_status =~ ($'\n'|^)M ]] && local _git_has_mods_cached=true
      [[ $_git_status =~ ($'\n'|^)A ]] && local _git_has_adds=true
      [[ $_git_status =~ ($'\n'|^)R ]] && local _git_has_renames=true
      [[ $_git_status =~ ($'\n'|^).D ]] && local _git_has_dels=true
      [[ $_git_status =~ ($'\n'|^)D ]] && local _git_has_dels_cached=true
      [[ $_git_status =~ ($'\n'|^)\?\? ]] && local _git_has_untracked_files=true
      [[ $_git_status =~ ($'\n'|^)[ADMR] && ! $_git_status =~ ($'\n'|^).[ADMR\?] ]] && local _git_ready_to_commit=true
      if [ "$_git_ready_to_commit" ]; then
         #for debug#echo "git ready to commit"
         PS_GIT="$PNRM$PGRN${_git_branch}✔$PNRM"
         (( _git_branch_len++ ))
      elif [ "$_git_has_mods_cached" -o "$_git_has_dels_cached" ]; then
         #for debug#echo "git has mods cached or has dels cached"
         PS_GIT="$PNRM$PCYN${_git_branch}+$PNRM"
         (( _git_branch_len++ ))
      elif [ "$_git_has_mods" -o "$_git_has_renames" -o "$_git_has_adds" -o "$_git_has_dels" ]; then
         #for debug#echo "git has mods or adds or dels"
         PS_GIT="$PNRM$PRED${_git_branch}*$PNRM"
         (( _git_branch_len++ ))
      elif [ "$_git_has_untracked_files" ]; then
         #for debug#echo "git has untracked files"
         PS_GIT="$PNRM$PYLW${_git_branch}$PNRM"
      else
         #for debug#echo "git has ???"
         _git_status=$(git status -bs 2> /dev/null)
         if [[ $_git_status =~ "[ahead " ]]; then
            local _gitahead=$(echo $_git_status | awk '{print $NF}' | cut -d']' -f1)
            PS_GIT="$PNRM$PMAG${_git_branch}>$_gitahead$PNRM"
            (( _git_branch_len += 1 + ${#_gitahead} ))
         else
            PS_GIT="$PNRM$PNRM${_git_branch}$PNRM"
         fi
      fi
      if [ "$_git_has_untracked_files" ]; then
         #PS_GIT="$PNRM[$PS_GIT$PYLW?$PNRM]"
         PS_GIT="$PNRM$PS_GIT$PYLW?$PNRM"
         (( _git_branch_len++ ))
      fi
      #PS_GIT="[$PS_GIT]"
      PS_GIT="$PS_GIT|"
   else   # NOT in a git repo
      PS_GIT=""
      local _git_branch_len=0
   fi
   # customize path depending on width/space available
   local _space_for_path=$(( $COLUMNS - $_versions_len - $_git_branch_len ))
   local _pwd=${PWD/$HOME/'~'}
   if [  ${#_pwd} -lt $_space_for_path ]; then
      PS_PATH="$PGRN\w$PNRM"
   else
      (( _space_for_path -= 2 ))
      local _ps_path_start_pos=$(( ${#_pwd} - $_space_for_path ))
      local _ps_path_chopped="..${_pwd:$_ps_path_start_pos:$_space_for_path}"
      PS_PATH="$PGRN${_ps_path_chopped}$PNRM"
   fi
   PS_WHO="$PBLU\u@\h$PNRM"
   # different themes
   ##PS1="$PS_PROJ $PS_GIT $PS_ANS $PS_PY $PGRN\w$PBLU\n\u@\h$PNRM|$PS_COL$ $PNRM"
   ##PS1="$PS_GIT $PS_ANS $PS_PY $PGRN\w$PBLU\n$PS_PROJ\u@\h$PNRM|$PS_COL$ $PNRM"
   ##PS1="$PGRN\w$PNRM [$PS_GIT]  $PS_ANS  $PS_PY\n$PS_PROJ$PBLU\u@\h$PNRM|$PS_COL$ $PNRM"
   ##PS1="\n$PS_PATH $PS_ANS $PS_PY\n$PS_PROJ$PS_WHO|$PS_COL$ $PNRM"
   ##PS1="\n$PS_ANS $PS_PY $PS_PATH\n$PS_PROJ$PS_WHO|$PS_COL$ $PNRM"
   #PS1="\n$PS_ANS $PS_PY $PS_PATH\n$PS_PROJ$PS_WHO[\j]$PS_COL$ $PNRM"
   if [ "$COMPANY" == "onica" -a -n "$ONICA_SSO_ACCOUNT_KEY" -a -n "$ONICA_SSO_EXPIRES_TS" ]; then
      local _now_ts=$(date +%s)
      if [ $ONICA_SSO_EXPIRES_TS -gt $_now_ts ]; then
         echo -ne "\033]0;$(whoami)@$(hostname)-[$ONICA_SSO_ACCOUNT_KEY]\007"
         if [ $(($ONICA_SSO_EXPIRES_TS - $_now_ts)) -lt 300 ]; then
            PS_PROJ="[$PYLW$ONICA_SSO_ACCOUNT_KEY$PNRM]"
            PS_COL=$PYLW
         else
            PS_PROJ="[$PRED$ONICA_SSO_ACCOUNT_KEY$PNRM]"
            PS_COL=$PRED
         fi
      else
         echo -ne "\033]0;$(whoami)@$(hostname)-[$ONICA_SSO_ACCOUNT_KEY](EXPIRED)\007"
         PS_PROJ="[$PGRY$ONICA_SSO_ACCOUNT_KEY$PNRM]"
         PS_COL=$PGRY
      fi
   else
      echo -ne "\033]0;$(whoami)@$(hostname)\007"
   fi
   #PS1="\n$PS_CHF $PS_ANS $PS_PY $PS_PATH\n$PS_PROJ$PS_WHO[\j]$PS_COL$ $PNRM"
   #PS1="\n$PS_CHF$PS_ANS$PS_PY $PS_PATH\n$PS_PROJ$PS_WHO[\j]$PS_COL$ $PNRM"
   if [ $(jobs | wc -l | tr -d ' ') -gt 1 ]; then
      # using "1" because the `git branch` above runs in the background
      PS1="\n$PS_GIT$PS_CHF$PS_ANS$PS_PY$PS_PATH\n$PS_PROJ$PS_WHO(\j)$PS_COL$ $PNRM"
   else
      PS1="\n$PS_GIT$PS_CHF$PS_ANS$PS_PY$PS_PATH\n$PS_PROJ$PS_WHO$PS_COL$ $PNRM"
   fi
}

function ccc {
   # Synchronize tmux windows
   for I in $@; do
      tmux splitw "ssh $I"
      tmux select-layout tiled
   done
   tmux set-window-option synchronize-panes on
   exit
}

function chkrepodiffs { # TOOL
   # usage: chkrepodiffs [-v] [file]
   # checks files in current dir against file in home dir for diffs
   # only works on https://github.com/pataraco/bash_aliases repo now
   # comparing those files against those in home directory
   cd ~/repos/bash_aliases
   local _verbose=$1
   if [ "$_verbose" == "-v" ]; then
      shift
   fi
   local _files=$*
   local _file
   [ -z "$_files" ] && _files=$(ls -A -I .git)
   for _file in $_files; do
      if [ -e $_file -a -e ~/$_file ]; then
         diff -q $_file ~/$_file
         if [ $? -eq 1 ]; then
            if [ "$_verbose" == "-v" ]; then
              read -p "Hit [Enter] to continue" junk
              diff $_file ~/$_file | \less -rX
              echo
            fi
         else
            echo "Files $_file and ~/$_file are the same"
         fi
      else
         [ ! -e $_file ] && ls $_file
         [ ! -e ~/$_file ] && ls ~/$_file
      fi
   done
   cd - > /dev/null
}

function chksums { # TOOL
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

function cktj { # TOOL
   # convert a key file so that it can be used in a 
   # json entry (i.e. change \n -> "\n")
   if [ -n "$1" ]; then
      cat $1 | tr '\n' '_' | sed 's/_/\\n/g'
      echo
   else
      echo "error: you did not specify a key file to convert"
   fi
}

function compare_lines {
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

# This is commented out because it was for a previous place of 
# employment using Informix
# TODO: update for mysql and uncomment
##function dbgrep { # TOOL
##   # search/grep informix DB for patterns in tables/column names
##   # OPTIONS
##   # -w search for whole words only
##   # -t search table  names for a pattern:
##   #     display "matching table names"
##   # -c search column names for a pattern:
##   #     display "matching column names"
##   # -i search table  names for a pattern and get info:
##   #     display "table name: column1, column2, etc."
##   # -a search for tables containing patterns in column name:
##   #     display "table name1, table name2, etc."
##   NOT_VALID_HOSTS="jump1 jump2 stcgxyjmp01"
##   USAGE="dbgrep [-w] -t|c|i|a PATTERN"
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

function decimal_to_base32 {
   # convert a decimal number to base 32
   BASE32=($(echo {0..9} {a..v}))
   arg1=$@
   for i in $(bc <<< "obase=32; $arg1"); do
      echo -n ${BASE32[$(( 10#$i ))]}
   done && echo
}

function decimal_to_base36 {
   # convert a decimal number to base 36
   BASE36=($(echo {0..9} {a..z}))
   arg1=$@
   for i in $(bc <<< "obase=36; $arg1"); do
      echo -n ${BASE36[$(( 10#$i ))]}
   done && echo
}

function decimal_to_baseN {
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

function dlecr {
   # run `docker login` command returned from `aws ecr get-login`
   local _DEFAULT_REGION="us-east-1"
   local _region=$1
   if [ -z "$_region" ]; then
      [ -n "$AWS_DEFAULT_REGION" ] && _region=$AWS_DEFAULT_REGION || _region=$_DEFAULT_REGION
   fi
   eval $(aws ecr get-login --no-include-email --region $_region)
}

function elbinsts {
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

function fdgr {
   # find dirty git repos
   local _orig_wd=$(pwd)
   local _REPOS_TO_CHECK="$(find $HOME -type d -name .git -exec dirname {} \;)"
   local _repo
   local _git_status
   for _repo in $_REPOS_TO_CHECK; do
      cd $_repo
      _gitstatus=$(git status --porcelain 2> /dev/null)
      [ -n "$_gitstatus" ] && echo -e "repo: $_repo status [${RED}DIRTY${NRM}]"
   done
   cd $_orig_wd
}

function gdate {
   # convert hex date value to date
   date --date=@`printf "%d\n" 0x$1`
}

##function getramsz { # TOOL
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

function gh { # TOOL
   # grep bash history for a PATTERN
   if [[ $* =~ ^\^.* ]]; then
      pattern=$(echo "$*" | tr -d '^')
      #echo "debug: looking for: ^[0-9]*  $pattern"
      history | grep "^[ 0-9]*  $pattern" | grep --color=always "$pattern"
   else
      #echo "debug: looking for: $*"
      history | grep --color=always "$*"
   fi
}

function gl { # TOOL
   # grep and pipe to less
   eval grep --color=always $@ | less
}

function j2y {
   # convert JSON to YAML (from either STDIN or by specifying a file
   if [ -n $1 ]; then
      cat $1 | python -c 'import json, sys, yaml; yaml.safe_dump(json.load(sys.stdin), sys.stdout)'
   else
      python -c 'import json, sys, yaml; yaml.safe_dump(json.load(sys.stdin), sys.stdout)'
   fi
}

function kf {
   # `knife` command wrapper to use my dynamically set knife.rb file
   if [ -z "$KNIFERB" ]; then
      echo "KNIFERB environment variable NOT set"
   else
      eval knife '$*' -c $KNIFERB
   fi
}

function lgr {
   # list GitHub Repos for a user
   local _DEFAULT_USER="pataraco"
   local _USER=${1:-$_DEFAULT_USER}
   curl -s https://api.github.com/users/$_USER/repos|grep clone_url|awk '{print $2}'|tr -d '",'
}

function listcrts {
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
   #echo "debug: opts: '$_openssl_opts'"
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

function listcrts2 {
   # another way to list all info in a crt bundle
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

function mkalias { # TOOL
   # make an alias and add it to this file
   if [[ $1 && $2 ]]; then
      echo "alias $1=\"$2\"" >> ~/.bash_aliases
      alias $1="$2"
   fi
}

function mktb { # MISC
   # get rid of all the MISC, RHUG, and TRUG functions from $BRCSRC
   # and save the rest to $BRCDST
   local BRCSRC=$HOME/.bashrc
   local BRCDST=$HOME/.bashrc.tools
   rm -f $BRCDST
   sed '/^function.*# MISC$/,/^}$/d;/^function.*# RHUG$/,/^}$/d;/^function.*# TRUG$/,/^}$/d' $BRCSRC > $BRCDST
}

function pag { # TOOL
   # run ps and grep for a pattern
   ps auxfw | grep $*
}

function peg { # TOOL
   # run ps and grep for a pattern
   ps -ef | grep $*
}

function pl {
   # run a command and pipe it through `less`
   eval $@ | less
}

function rac { # MISC
   # remember AWS CLI command - save the given command for later retreval
   COMMAND="$*"
   COMMANDS_FILE=$HOME/.aws_commands.txt
   echo "$COMMAND" >> $COMMANDS_FILE
   sort $COMMANDS_FILE > $COMMANDS_FILE.sorted
   /bin/cp -f $COMMANDS_FILE.sorted $COMMANDS_FILE
   /bin/rm -f $COMMANDS_FILE.sorted
   echo "added: '$COMMAND'"
   echo "   to: $COMMANDS_FILE"
}

function rc { # MISC
   # remember command - save the given command for later retreval
   COMMAND="$*"
   COMMANDS_FILE=$HOME/.commands.txt
   echo "$COMMAND" >> $COMMANDS_FILE
   sort $COMMANDS_FILE > $COMMANDS_FILE.sorted
   /bin/cp -f $COMMANDS_FILE.sorted $COMMANDS_FILE
   /bin/rm -f $COMMANDS_FILE.sorted
   echo "added: '$COMMAND'"
   echo "   to: $COMMANDS_FILE"
}

function rf { # MISC
   # remember file - save the given file for later retreval
   FILE="$*"
   FILES_FILE=$HOME/.files.txt
   echo "$FILE" >> $FILES_FILE
   sort $FILES_FILE > $FILES_FILE.sorted
   /bin/cp -f $FILES_FILE.sorted $FILES_FILE
   /bin/rm -f $FILES_FILE.sorted
   echo "added '$FILE' to: $FILES_FILE"
}

function sae { # TOOL
   # set AWS environment variables from ~/.aws/config file and profiles in it
   local _AWS_CFG=$HOME/.aws/config
   local _AWS_PROFILES=$(grep '^\[profile' $_AWS_CFG | awk '{print $2}' | tr ']\n' ' ')
   local _VALID_ARGS=$(echo $_AWS_PROFILES unset | tr ' ' ':')
   local _environment
   local _arg="$1"
   if [ -n "$_arg" ]; then
      if [[ ! $_VALID_ARGS =~ ^$_arg:|:$_arg:|:$_arg$ ]]; then
         echo -e "WTF? Try again... Only these profiles exist (or use 'unset'):\n   " $_AWS_PROFILES
         return 2
      fi
      [ "$COMPANY" == "onica" ] && ssol unset > /dev/null 2>&1
      if [ "$_arg" == "unset" ]; then
         unset AWS_DEFAULT_PROFILE
         unset AWS_ENVIRONMENT
         unset AWS_ACCESS_KEY_ID
         unset AWS_SECRET_ACCESS_KEY
         unset AWS_DEFAULT_REGION
         echo "environment has been unset"
      else
         export AWS_DEFAULT_PROFILE=$_arg # for `aws` CLI (instead of using --profile)
         local _aws_env=$(awk '$2~/'"$AWS_DEFAULT_PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/aws_account_desc/) {print $3,$4,$5,$6; exit}; (pfound=="true" && $1~/profile/) {exit}' $_AWS_CFG | sed 's/ *$//')
         local _aws_acct=$(aws sts get-caller-identity --profile $AWS_DEFAULT_PROFILE | jq -r .Account)
         export AWS_ENVIRONMENT="$_aws_env [$_aws_acct]"
         export AWS_ACCESS_KEY_ID=$(awk '$2~/'"$AWS_DEFAULT_PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/aws_access_key_id/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' $_AWS_CFG)
         export AWS_SECRET_ACCESS_KEY=$(awk '$2~/'"$AWS_DEFAULT_PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/aws_secret_access_key/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' $_AWS_CFG)
         export AWS_DEFAULT_REGION=$(awk '$2~/'"$AWS_DEFAULT_PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/region/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' $_AWS_CFG)
         _environment=$(awk '$2~/'"$AWS_DEFAULT_PROFILE"']/ {pfound="true"; next}; (pfound=="true" && $1~/environment/) {print $NF; exit}; (pfound=="true" && $1~/profile/) {exit}' $_AWS_CFG)
         echo "environment has been set to --> $AWS_ENVIRONMENT ($AWS_DEFAULT_PROFILE)"
         [ -z "$AWS_DEFAULT_PROFILE" ] && unset AWS_DEFAULT_PROFILE
         [ -z "$AWS_ENVIRONMENT" ] && unset AWS_ENVIRONMENT
         [ -z "$AWS_ACCESS_KEY_ID" ] && unset AWS_ACCESS_KEY_ID
         [ -z "$AWS_SECRET_ACCESS_KEY" ] && unset AWS_SECRET_ACCESS_KEY
         [ -z "$AWS_DEFAULT_REGION" ] && unset AWS_DEFAULT_REGION
      fi
      if [ "$COLOR_PROMPT" == "yes" ]; then
         case $_environment in
            dev)	# cyan prompt
               PS_COL="$PCYN"; PS_PROJ="$PS_COL[$AWS_DEFAULT_PROFILE]$PNRM" ;;
            test)	# magenta prompt
               PS_COL="$PMAG"; PS_PROJ="$PS_COL[$AWS_DEFAULT_PROFILE]$PNRM" ;;
            mixed)	# yellow prompt
               PS_COL="$PYLW"; PS_PROJ="$PS_COL[$AWS_DEFAULT_PROFILE]$PNRM" ;;
            prod)	# red prompt
               PS_COL="$PRED"; PS_PROJ="$PS_COL[$AWS_DEFAULT_PROFILE]$PNRM" ;;
            mine)	# green prompt
               PS_COL="$PGRN"; PS_PROJ="$PS_COL[$AWS_DEFAULT_PROFILE]$PNRM" ;;
            *)		# cyan prompt
               PS_COL="$PCYN"; PS_PROJ="$PNRM" ;;
         esac
      fi
   else
      echo -n "--- AWS Environment "
      [ -n "$AWS_DEFAULT_PROFILE" ] && echo "Settings ---" || echo "(NOT set) ---"
      echo "AWS_ENVIRONMENT       = ${AWS_ENVIRONMENT:-N/A}"
      echo "AWS_DEFAULT_PROFILE   = ${AWS_DEFAULT_PROFILE:-N/A}"
      # obfuscate the KEYs with some *'s
      echo "AWS_ACCESS_KEY_ID     = ${AWS_ACCESS_KEY_ID:-N/A}" | sed 's/[F-HO-QU-V0-9]/*/g'
      echo "AWS_SECRET_ACCESS_KEY = ${AWS_SECRET_ACCESS_KEY:-N/A}" | sed 's/[F-HO-QU-V0-9]/*/g'
      echo "AWS_DEFAULT_REGION    = ${AWS_DEFAULT_REGION:-N/A}"
   fi
}

function showf { # TOOL
   # show a function defined in in this file
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

function source_ssh_env {
   # shource ~/.ssh/environment file for ssh-agent
   SSH_ENV="$HOME/.ssh/environment"
   if [ -f "$SSH_ENV" ]; then
      source $SSH_ENV > /dev/null
      ps -u $USER | grep -q "$SSH_AGENT_PID.*ssh-agent$" || start_ssh_agent
   else
      start_ssh_agent
   fi
}

function sse {
   # ssh in to a server as user "ec2-user" and run optional command
   local _this_function="sse"
   local _user="ec2-user"
   if [ "$1" != "" ]; then
      _server=$1
      shift
      if [ "$*" == "" ]; then
         ssh $_user@${_server}
      else
         ssh $_user@${_server} "$*"
      fi
   else
      echo "USAGE: $_this_function HOST [COMMAND(S)]"
   fi
}

##function sshc { # TOOL
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

function ssu {
   # ssh in to a server as user "ubuntu" and run optional command
   local _this_function="ssu"
   local _user="ubuntu"
   if [ "$1" != "" ]; then
      _server=$1
      shift
      if [ "$*" == "" ]; then
         ssh $_user@${_server}
      else
         ssh $_user@${_server} "$*"
      fi
   else
      echo "USAGE: $_this_function HOST [COMMAND(S)]"
   fi
}

function start_ssh_agent {
   # start ssh-add agent
   SSH_ENV="$HOME/.ssh/environment"
   echo -n "Initializing new SSH agent... "
   /usr/bin/ssh-agent | sed 's/^echo/#echo/' > $SSH_ENV
   echo "succeeded"
   chmod 600 $SSH_ENV
   source $SSH_ENV > /dev/null
   /usr/bin/ssh-add
}

function stopwatch { # TOOL
   # display a "stopwatch"
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
      echo -ne "  Start: ${GRN}$_started${NRM} - Finish: ${RED}$_current${NRM} Delta: ${YLW}$(date +%T -d "0 $_current_secs secs - $_start_secs secs secs")${NRM}\r"
   done
}

function tb {
   # set xterm title to custom value
   echo -ne "\033]0; $* \007"
}

function tsend {
   # Send same command to all tmux panes
   tmux set-window-option synchronize-panes on
   tmux send-keys "$@" Enter
   tmux set-window-option synchronize-panes off
}

function vin {
   # vim certain files by alias
   NOTES_DIR="notes"
   note_file=$1
   if [ -n "$note_file" ]; then
      case $note_file in
         ansible) actual_note_file=Ansible_Notes.txt        ;;
             aws) actual_note_file=AWS_Notes.txt            ;;
           awsas) actual_note_file=AWS_AutoScaling_Notes.txt;;
            bash) actual_note_file=Bash_Notes.txt           ;;
            chef) actual_note_file=Chef_Notes.txt           ;;
          consul) actual_note_file=Consul_Notes.txt         ;;
          docker) actual_note_file=Docker_Notes.txt         ;;
              es) actual_note_file=ElasticSearch_Notes.txt  ;;
             git) actual_note_file=Git_Notes.txt            ;;
          gitlab) actual_note_file=GitLab_Notes.txt         ;;
         jenkins) actual_note_file=Jenkins_Notes.txt        ;;
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

function wtac { # MISC
   # what's that AWS command - retrieve the given command for use
   COMMAND_PATTERN="$*"
   COMMANDS_FILE=$HOME/.aws_commands.txt
   grep --colour=always "$COMMAND_PATTERN" $COMMANDS_FILE
   while read _line; do
      history -s "$_line"
   done <<< "$(grep "$COMMAND_PATTERN" $COMMANDS_FILE | sed 's:\\:\\\\:g')"
}

function wtc { # MISC
   # what's that command - retrieve the given command for use
   COMMAND_PATTERN="$*"
   COMMANDS_FILE=$HOME/.commands.txt
   grep --colour=always "$COMMAND_PATTERN" $COMMANDS_FILE
   while read _line; do
      history -s "$_line"
   done <<< "$(grep "$COMMAND_PATTERN" $COMMANDS_FILE | sed 's:\\:\\\\:g')"
}

function wtf { # MISC
   # what's that file - retrieve the given file for use
   # sets var $file to the last one found to use
   FILE_PATTERN="$*"
   FILES_FILE=$HOME/.files.txt
   grep --colour=always $FILE_PATTERN $FILES_FILE
   file=`grep $FILE_PATTERN $FILES_FILE | tail -1`
}

function wutch {
   # like `watch` but colorful
   # couldn't get the trap to work
   #   just remove all "out" files - they'll get quickly replaced
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

function xsse {
   # ssh in to a server in a seperate xterm window as user: "ec2-user"
   if [ -n "$1" ]; then
      local _server=$1
      $XTERM -e 'eval /usr/bin/ssh -q ec2-user@'"$_server"'' &
   else
      echo "USAGE: xsse HOST"
   fi
}

function xssh {
   # ssh in to a server in a seperate xterm window
   if [ -n "$1" ]; then
      local _server=$1
      $XTERM -e 'eval /usr/bin/ssh -q '"$_server"'' &
   else
      echo "USAGE: xssh HOST"
   fi
}

function y2j {
   # convert YAML to JSON (from either STDIN or by specifying a file
   if [ -n $1 ]; then
      cat $1 | python -c 'import json, sys, yaml; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)'
   else
      #python -c 'import json, sys, yaml; y=yaml.load(sys.stdin.read()); print json.dump(y)'
      python -c 'import json, sys, yaml; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)'
   fi
}

function zipstuff {	# MISC
   # zip up specified files for backup
   STUFFZIP="$HOME/.$COMPANY.stuff.zip"
   FILES="
      .*rc
      .ansible.cfg
      .aws_commands.txt
      .aws/config
      .bash*
      .csshrc
      .commands.txt
      .gitconfig
      .gitignore
      .git-credentials
      .files.txt
      .s3cfg
      .ssh/config
      .ssh/environment
      .tmux.conf
      automation
      notes
      projects
      scripts"
   # didn't figure out how to make this work
   ##EXCLUDE_FILES="*/.hg/\* repos/.chef/checksums/\* *.zip"
   cd
   thisserver=`hostname`
   echo "ziping $FILES to $STUFFZIP... "
   ##/usr/bin/zip -ru $STUFFZIP $FILES -x $EXCLUDE_FILES
   ##/usr/bin/zip -ru $STUFFZIP $FILES -x */.hg/\* repos/.chef/checksums/\* */*/.git/\* */*.zip */*/*.zip
   /usr/bin/zip -ru $STUFFZIP $FILES -x */.hg/\* */.git/\* */*/.git/\* */*.zip */*/*.zip
   echo done
}

# -------------------- define aliases --------------------

alias ~="cd ~"
alias ..="cd .."
alias -- -="cd -"
#alias a="alias" # use: `sa`
#alias a="alias | cut -d= -f1 | sort | awk -v c=6 'BEGIN{print \"\n\t--- Aliases (use \`sa\` to show details) ---\"}{if(NR%c){printf \"  %-12s\",\$2}else{printf \"  %-12s\n\",\$2}}END{print CR}'"
alias a="alias | grep -v ^declare | cut -d= -f1 | sort | awk -v c=5 'BEGIN{print \"\n\t--- Aliases (use \`sa\` to show details) ---\"}{if(NR%c){printf \"  %-12s\",\$2}else{printf \"  %-12s\n\",\$2}}END{print CR}'"
#alias awsrlhz="aws route53 list-hosted-zones |jq -r .HostedZones[].Name|sort|sed 's/\.$//'"
#alias awsrlhz="aws route53 list-hosted-zones | jq -r '.HostedZones[] | \"Zone: \" + .Name + \"   ID: \" +  .Id' | sort | sed 's/\. //'"
alias awsrlhz="aws route53 list-hosted-zones | jq -r '.HostedZones[] | .Name + .Id + \")\"' | sort | sed 's:\./hostedzone/: (:'"
alias c="clear"
alias cdh="cd ~; cd"
alias cd-ia="cd ~/repos/infrastructure-automation/exercises/auto_website"
alias cd-t="cd ~/repos/troposphere"
alias cols="tsend 'echo \$COLUMNS'"
alias cp='cp -i'
alias crt='~/scripts/chef_recipe_tree.sh'
#alias cssh='cssh -o "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"'
alias diff="colordiff -u"
alias disp="tsend 'echo \$DISPLAY'"
alias eaf="eval \"$(declare -F | sed -e 's/-f /-fx /')\""
alias egrep="egrep --color=auto"
alias egrpq="egrep --color=always"
#alias f="declare -F | awk '{print \$3}' | more"
#alias f="declare -F | awk -v c=4 'BEGIN{print \"\n\t--- Functions (use \`sf\` to show details) ---\"}{if(NR%c){printf \"  %-15s\",\$3}else{printf \"  %-15s\n\",\$3}}END{print CR}'"
alias f="grep '^function .* ' ~/.bash_aliases | awk '{print $2}' | cut -d'(' -f1 | sort | awk -v c=4 'BEGIN{print \"\n\t--- Functions (use \`sf\` to show details) ---\"}{if(NR%c){printf \"  %-18s\",\$2}else{printf \"  %-18s\n\",\$2}}END{print CR}'"
alias fgrep="fgrep --color=auto"
alias fgrpa="fgrep --color=always"
alias fuck='echo "sudo $(history -p \!\!)"; sudo $(history -p \!\!)'
# alias gh="history | grep" # now a function
alias ghwb="sudo dmidecode | egrep -i 'date|bios'"
alias ghwm="sudo dmidecode | egrep -i '^memory device$|	size:.*B'"
alias ghwt='sudo dmidecode | grep "Product Name"'
#alias grep="grep --color=always"
alias grep="grep --color=auto"
alias grpa="grep --color=always"
alias guid='printf "%x\n" `date +%s`'
alias h="history | tail -20"
alias kaj='eval kill $(jobs -p)'
if [ "$(uname -s)" == "Darwin" ]; then
   alias l.='ls -dGh .*'
   alias la='ls -aGh'
   alias ll='ls -lGh'
   alias lla='ls -laGh'
   alias ls='ls -CFGh'
else
   alias l.='ls -dh .* --color=auto'
   alias la='ls -ah --color=auto'
   alias ll='ls -lh --color=auto'
   alias lla='ls -lah --color=auto'
   alias ls='ls -CFh --color=auto'
fi
alias less="less -FrX"
alias laan="for p in \$(grep '^\[profile' ~/.aws/config | awk '{print \$2}' | tr ']\n' ' '); do echo -en \"\$p: \"; echo \$(aws sts get-caller-identity --profile \$p | jq -r .Account); done"
alias mv='mv -i'
#alias psa='ps auxfw' # converted to a function
alias myip='curl http://ipecho.net/plain; echo'
alias pa='ps auxfw'
#alias pse='ps -ef' # converted to a function
alias pe='ps -ef'
alias pssav='PS_SHOW_AV=1'
alias psscv='PS_SHOW_CV=1'
alias psspv='PS_SHOW_PV=1'
alias pssallv='PS_SHOW_AV=1; PS_SHOW_CV=1; PS_SHOW_PV=1'
alias pshav='PS_SHOW_AV=0; unset PS_ANS'
alias pshcv='PS_SHOW_CV=0; unset PS_CHF'
alias pshpv='PS_SHOW_PV=0; unset PS_PY'
alias pshallv='PS_SHOW_AV=0; PS_SHOW_CV=0; PS_SHOW_PV=0; unset PS_ANS; unset PS_CHF; unset PS_PY'
alias ccrlf="sed -e 's//\n/g' -i .orig"
alias rcrlf="sed -e 's/$//g' -i .orig"
#alias ring="$HOME/scripts/tools/ring.sh"
alias ring="$HOME/repos/ring/ring.sh"
alias rsshk='ssh-keygen -f "$HOME/.ssh/known_hosts" -R'
alias rm='rm -i'
alias sa=alias
#alias sba='echo -n "sourcing ~/.bash_aliases... "; source ~/.bash_aliases > /dev/null; echo "done"'
# the following doesn't work and doesn't seem to allow changes to take affect
#alias sba='source ~/.bash_aliases | sed "s/$/.../g" | tr "\n" " "; echo "done"'
alias sba='source ~/.bash_aliases'
alias sdl="export DISPLAY=localhost:10.0"
alias sf=showf
alias shit='echo "sudo $(history -p \!\!)"; sudo $(history -p \!\!)'
alias sing="$HOME/scripts/tools/sing.sh"
alias sts="grep '= CFNType' $HOME/repos/stacker/stacker/blueprints/variables/types.py | awk '{print \$1}'"
alias sw=stopwatch
#alias vagssh='cd ~/cloud_automation/vagrant/CentOS65/; vagrant ssh' # now a function
#alias tt='echo -ne "\e]62;`whoami`@`hostname`\a"'
alias ta='tmux attach -t'
alias tmx='tmux new-session -s Raco -n MYSHIT'
alias tspo='tmux set-window-option synchronize-panes on'
alias tspx='tmux set-window-option synchronize-panes off'
alias tt='echo -ne "\033]0;$(whoami)@$(hostname)\007"'
alias tskap="_tmux_send_keys_all_panes"
alias xterm='xterm -fg white -bg black -fs 10 -cn -rw -sb -si -sk -sl 5000'
alias u=uptime
#alias vba='echo -n "editing ~/.bash_aliases... "; vi ~/.bash_aliases; echo "done"; echo -n "sourcing ~/.bash_aliases... "; source ~/.bash_aliases > /dev/null; echo "done"'
#alias vba='echo -n "editing ~/.bash_aliases... "; vi ~/.bash_aliases; sba'
alias vba='echo "editing: ~/.bash_aliases"; vi ~/.bash_aliases; sba'
alias vcba='[ -f $COMPANY_SHIT ] && { echo "editing: $COMPANY_SHIT"; vi $COMPANY_SHIT; sba; }'
alias veba='[ -f $ENVIRONMENT_SHIT ] && { echo "editing: $ENVIRONMENT_SHIT"; vi $ENVIRONMENT_SHIT; sba; }'
#alias vi='`which vim`'
#alias view='`which vim` -R'
# upgrade to neovim
alias vi='$(which nvim)'
alias vid='$(which nvim) -d'
alias vih='$(which nvim) -o'
alias viv='$(which nvim) -O'
alias vit='$(which nvim) -p'
alias viw='$(which nvim) -R'
alias view='$(which nvim) -R'
# alias vms="set | egrep 'CLUST_(NEW|OLD)|HOSTS_(NEW|OLD)|BRNCH_(NEW|OLD)|ES_PD_TSD|SDELEGATE|DB_SCRIPT|VAULT_PWF|VPC_NAME'"
if [ "$(uname -s)" == "Darwin" ]; then
   alias which='(alias; declare -f) | /usr/bin/which'
elif [ "$(uname -so)" == "Linux GNU/Linux" ]; then
   alias which='(alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot'
else
   alias which='(alias; declare -f) | /usr/bin/which'
fi
alias wgft='echo "$(history -p \!\!) | grep"; $(history -p \!\!) | grep'
alias whoa='echo "$(history -p \!\!) | less"; $(history -p \!\!) | less'

# -------------------- final touches --------------------

# source company specific functions and aliases
[ -f $COMPANY_SHIT ] && source $COMPANY_SHIT

# source environment specific functions and aliases
[ -f $ENVIRONMENT_SHIT ] && source $ENVIRONMENT_SHIT

# set bash prompt command (and bash prompt)
export OLD_PROMPT_COMMAND=$PROMPT_COMMAND
export PROMPT_COMMAND="bash_prompt"

[ -n "$PS1" ] && echo -n ".bash_aliases (end). "
