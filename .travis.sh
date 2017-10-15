#!/bin/bash

########################################
# Function to gather master style output
# arguments: file path to write rake sytle output
# post-condition: the file path has rake style output
# returns: 1 on error
function gather_master_style {
  local my_branch=$(git branch | grep '^* ' | sed 's/^* //')
  if [[ -z $1 ]]; then
    echo -e 'gather_master_style:\tNeeds a filename to write rake style report' \
            'got nothing' > /dev/stderr
    return 1
  fi
  if [[ -n $(git status -s) ]]; then
    echo -e 'gather_master_style:\tWorkspace is not up-to-date; will fail!' \
      > /dev/stderr
    return 1
  fi
  if [[ -z ${my_branch:=${TRAVIS_BRANCH}} ]]; then
    echo -e 'gather_master_style:\tFailed to get a current Git branch!' \
      > /dev/stderr
    return 1
  fi
  git remote add bloomberg https://github.com/bloomberg/chef-bach \
    >/dev/null 2>&1
  git fetch bloomberg master >/dev/null 2>&1
  git checkout bloomberg/master >/dev/null 2>&1
  if [[ $(git branch | grep '^* ' | sed 's/^* //') != \
        '(HEAD detached at bloomberg/master)' ]]; then
    echo -e 'gather_master_style:\tFailed to pull Bloomberg master' \
      > /dev/stderr
    return 1
  fi
  rake style >$1 2>&1 || true
  git checkout ${my_branch} >/dev/null 2>&1
}

####################################################
# Function to parse FoodCritic Rake output to return
# the number of offenses
# arguments: file path with rake sytle output
#            (or will wait for standard-in to close)
# output: the integer number of offenses
function gather_chef_style_offenses {
  egrep '^FC[0-9]*:' $1 | wc -l
}


#################################################
# Function to parse RuboCop Rake output to return
# the number of offenses
# arguments: file path with rake sytle output
#            (or will wait for standard-in to close)
# output: the integer number of offenses
function gather_ruby_style_offenses {
  sed -n 's/^[0-9]* files inspected, \([0-9]*\) offenses detected$/\1/p' $1
}

###############################################
# Function to compare rake style outputs to see
# if the number of offenses if more than master
# argument: file path with local rake sytle output
# output: admonishment or congratulations for the
#         code under validation
# returns: 0: if there are fewer or equal offenses
#          1: if there are more offenses
#          2: if there was an error
function compare_offenses {
  if [[ -z $1 || ! -e $1 ]]; then
    echo -e 'compare_offenses:\tNeeds a filename with a rake style report' \
            "got: $1" > /dev/stderr
    return 2
  fi
  local master_style_file="${REPORT_DIR}/master_style.txt"
  gather_master_style ${master_style_file} || return 2
  local master_ruby_offenses=$(gather_ruby_style_offenses ${master_style_file})
  local master_chef_offenses=$(gather_chef_style_offenses ${master_style_file})
  local my_ruby_offenses=$(gather_ruby_style_offenses $1)
  local my_chef_offenses=$(gather_chef_style_offenses $1)
  if [[ -z "$master_ruby_offenses" || -z "$my_ruby_offenses" ]]; then 
    echo -e 'compare_offenses:\tFailed to gather Ruby offenses:\n' \
            "\tmaster:\t${master_ruby_offenses}\n\tmine:\t${my_ruby_offenses}"\
            "\n\tMaster style file ${master_style_file}"
    return 2
  elif [[ -z "$master_chef_offenses" || -z "$my_chef_offenses" ]]; then 
    echo -e 'compare_offenses:\tFailed to gather Chef offenses:\n' \
            "\tmaster:\t${master_chef_offenses}\n\tmine:\t${my_chef_offenses}"
            "\n\tMaster style file ${master_style_file}"
    return 2
  fi
  echo "Found my offenses are Ruby: ${my_ruby_offenses} " \
       "Chef: ${my_chef_offenses} versus Ruby: ${master_ruby_offenses}" \
       "Chef: ${master_chef_offenses}"
  if (( ${master_ruby_offenses} <= ${my_ruby_offenses} || \
        ${master_chef_offenses} <= ${my_chef_offenses})); then
    echo "## This is terrible."
    return 1
  else
    echo "## This is an improvement."
    return 0
  fi
}

function setup_report_dir {
  export REPORT_DIR=$(mktemp -d --suffix '_travis_chef-bach_build_out')
  echo "Using REPORT_DIR: ${REPORT_DIR}" >/dev/stderr
}
