# system-wide profile.modules                                          #
# Initialize modules for all sh-derivative shells                      #
#----------------------------------------------------------------------#
trap "" 1 2 3

case "$0" in
    -bash|bash|*/bash) . /usr/share/lmod/lmod/init/bash ;;
       -ksh|ksh|*/ksh) . /usr/share/lmod/lmod/init/ksh ;;
       -zsh|zsh|*/zsh) . /usr/share/lmod/lmod/init/zsh ;;
          -sh|sh|*/sh) . /usr/share/lmod/lmod/init/sh ;;
                    *) . /usr/share/lmod/lmod/init/sh ;;  # default for scripts
esac

trap - 1 2 3
