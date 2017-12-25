divert(-1)dnl
#
# etc.m4
# Core Definitions 
# Etc Deployment System
# 

#Constants
pushdef(TRUE, 1)
pushdef(FALSE, 0)
pushdef(WORK_DIR,.etc)
pushdef(CHOMP,`patsubst($1,`\s*',)')
pushdef(NEWLINE,`
')

#Operating System
define(ETC_OS_MACOS,Darwin)
define(ETC_OS_LINUX,Linux)
define(ETC_OS, `CHOMP(esyscmd(uname -s))')

#Uility Macros
define(ETC_INSTALLED, `ifelse(CHOMP(esyscmd(command -v $1)),,FALSE,TRUE)')
define(ETC_EXISTS, `syscmd(test -e $1)ifelse(sysval,0,TRUE,FALSE)')

dnl Usage: ETC_SELECT_BEGIN(<name>)
dnl .... <use make macros using selection> ...
dnl ETC_SELECT_END(<name>)
dnl
define(ETC_SELECT_BEGIN,`pushdef(ETC_SELECTION,$1)')
define(ETC_SELECT_END,`popdef(ETC_SELECTION)')

#Conditionals
dnl Usage: ETC_IF_OS(<OS>,<TRUE>,<FALSE>)
dnl Expands to 'TRUE' if current Operating System is indeed 'OS', else expands
dnl to 'FALSE'.
dnl
define(ETC_IF_OS,`ifelse(ETC_OS,$1,$2,$3)')

dnl Usage: ETC_IF_OS(<OS>,<TRUE>,<FALSE>)
dnl Expands to 'TRUE' if 'name' is installed else expands to 'FALSE'.
dnl
define(ETC_IF_INSTALLED,`ifelse(ETC_INSTALLED($1),TRUE,$2,$3)')

#Make Macros
dnl Usage: ETC_TARGET([<name>])
dnl Expands to the marker path of 'name', if 'name' is obmitted, gives marker
dnl path of current selection.
dnl
define(ETC_TARGET,`dnl
ifelse(eval($# < 1),TRUE,`ETC_TARGET(ETC_SELECTION)',WORK_DIR/mark_$1)')

dnl Usage: ETC_DEPEND(<dependency>,[<dependent>])
dnl Makes 'dependent' depend on 'dependency'
dnl if 'name' is obmitted, makes current selection depend on 'dependency'
dnl
define(ETC_DEPEND,`dnl
ifelse(eval($# > 1),TRUE,ETC_TARGET($1): ETC_TARGET($2),dnl
ETC_TARGET(ETC_SELECTION): ETC_TARGET($1))')

dnl Usage: ETC_MARK([name])
dnl Marks 'name' status as completed and fullfills any dependency created by
dnl 'name'
dnl
define(ETC_MARK,`dnl
ifelse(eval($# < 1),TRUE,`ETC_MARK(ETC_SELECTION)',dnl
touch -f ETC_TARGET($1))')

dnl Usage: ETC_UNMARK([name])
dnl Marks 'name' status as incomplete and unfullfills any dependency created by
dnl 'name'
dnl
define(ETC_UNMARK,`dnl
ifelse(eval($# < 1),TRUE,`ETC_UNMARK(ETC_SELECTION)',dnl
rm -f ETC_TARGET($1))')

#Fetch&ExtractMacros
dnl Usage: ETC_RETRIEVE('url', 'destination')
dnl Attempts to retrieve the resource pointed to at 'url' to the filepath at
dnl 'destination'
dnl
define(ETC_RETRIEVE,'dnl
ifelse(ETC_INSTALLED(aria2c),TRUE,aria2c -x 10 -s 10 -o $2 $1,dnl
ifelse(ETC_INSTALLED(curl),TRUE,curl -o $2 $1))')


dnl Usage: ETC_RETRIEVE(<path>)
dnl Extract .tar.gz pointed by 'path' to the current directory.
dnl
define(ETC_EXTRACT_TGZ, `tar -xzf $1')

#Hooks
dnl Usage: ETC_HOOK([name],implementation)
dnl Define a hook  to be run after 'name'  changes or is modified in 
dnl some way, whether that is an install, update or removal. 
dnl Only one hook for a 'name' can be defined at a given time, further 
dnl invocations would override the previous hook
dnl If 'name' is not given, would use current selection.
dnl 
define(ETC_HOOK,`
ifelse(eval($# < 2),TRUE,`ETC_HOOK(ETC_SELECTION,$1)',dnl
`define(__ETC_HOOK_$1__,$2)')')

dnl Usage: ETC_HOOK_EVOLVE([name],implementation)
dnl Define a hook  to be run after 'name' is installed or updated, (ie evolve)
dnl Only one evolve hook for a 'name' can be defined at a given time, further 
dnl invocations would override the previous evolve hook.
dnl If 'name' is not given, would use current selection.
dnl
define(ETC_HOOK_EVOLVE,`
ifelse(eval($# < 2),TRUE,`ETC_HOOK_EVOLVE(ETC_SELECTION,$1)',dnl
`define(__ETC_HOOK_EVOLVE_$1__,$2)')')

dnl Usage: ETC_HOOK_EVOLVE([name],implementation)
dnl Define a hook  to be run after 'name' is removed,
dnl Only one cremate hook for a 'name' can be defined at a given time, further 
dnl invocations would override the previous cremate hook.
dnl If 'name' is not given, would use current selection.
dnl
define(ETC_HOOK_CREMATE,`
ifelse(eval($# < 2),TRUE,`ETC_HOOK_CREMATE(ETC_SELECTION,$1)',dnl
`define(__ETC_HOOK_CREMATE_$1__,$2)')')

#Make Methods
#Generics
#TODO; Invergrate generic make generator into use in higher level macros below.
dnl Usage: ETC_GEN_MAKE(name,install,update,remove)
dnl Generates makefile rules for making current selection for the given install, 
dnl update dnl and removal command for 'name'
dnl 
define(ETC_GEN_MAKE, `dnl
.PHONY: install update remove
install: ETC_TARGET($1)
ETC_TARGET($1):
patsubst(`$2',NEWLINE,NEWLINE	)
	patsubst(ifdef(`__ETC_HOOK_$1__',__ETC_HOOK_$1__,),NEWLINE,NEWLINE	)
	patsubst(ifdef(`__ETC_HOOK_EVOLVE_$1__',__ETC_HOOK_EVOLVE_$1__,),NEWLINE,NEWLINE	)
update:
patsubst(`$3',NEWLINE,NEWLINE	)
	patsubst(ifdef(`__ETC_HOOK_$1__',__ETC_HOOK_$1__,),NEWLINE,NEWLINE	)
	patsubst(ifdef(`__ETC_HOOK_EVOLVE_$1__',__ETC_HOOK_EVOLVE_$1__,),NEWLINE,NEWLINE	)
remove:
patsubst(`$4',NEWLINE,NEWLINE	)
	patsubst(ifdef(`__ETC_HOOK_$1__',__ETC_HOOK_$1__,),NEWLINE,NEWLINE	)
	patsubst(ifdef(`__ETC_HOOK_CREMATE_$1__',__ETC_HOOK_CREMATE_$1__,),NEWLINE,NEWLINE	)
')

#Package Manager 
dnl Usage: ETC_PKG_SELECT([brew|apt-get|apt-fast|pip])
dnl Select the package manager referenced by 'name' for use.
dnl If argument is obmitted, reset package manager selection to default.
dnl If selected package manager isnt supported, would expand to an empty string
dnl
define(ETC_PKG_SELECT,`dnl
ifelse(ETC_INSTALLED($1),TRUE, `pushdef(`ETC_PKG_MANAGER', $1)',dnl
ifelse(ETC_INSTALLED(brew),TRUE,`pushdef(`ETC_PKG_MANAGER', brew)',dnl
ifelse(ETC_INSTALLED(apt-get),TRUE, `pushdef(`ETC_PKG_MANAGER', apt-get)',dnl
ifelse(ETC_INSTALLED(apt-fast),TRUE, `pushdef(`ETC_PKG_MANAGER', apt-fast)'))))')

dnl Usage: ETC_PKG_INSTALL(name)
dnl Expands to the command used to install the package 'name' using the current
dnl selected package manager. 
dnl If selected package manager isnt supported, would expand to an empty string
dnl
define(ETC_PKG_INSTALL,`dnl
ifelse(ETC_PKG_MANAGER,brew,brew install $1,dnl
ifelse(ETC_PKG_MANAGER,apt-get,sudo apt-get -y install $1,dnl
ifelse(ETC_PKG_MANAGER,apt-fast,sudo apt-fast -y install $1,dnl
ifelse(ETC_PKG_MANAGER,pip,pip install $1,dnl
ifelse(ETC_PKG_MANAGER,pip3,pip3 install $1)))))')

dnl Usage: ETC_PKG_UPDATE(<name>)
dnl Expands to the command used to update the package 'name' using the current
dnl selected package manager.
dnl If selected package manager isnt supported, would expand to an empty string
dnl 
define(ETC_PKG_UPDATE,`dnl
ifelse(ETC_PKG_MANAGER,brew,brew update; brew upgrade $1,dnl
ifelse(ETC_PKG_MANAGER,apt-get,sudo apt-get -y update; sudo apt-get -y upgrade $1,dnl
ifelse(ETC_PKG_MANAGER,apt-fast,sudo apt-fast -y update; sudo apt-fast -y upgrade $1,dnl
ifelse(ETC_PKG_MANAGER,pip,pip install --upgrade,dnl
ifelse(ETC_PKG_MANAGER,pip3,pip3 install --upgrade)))))')

dnl Usage: ETC_PKG_UPDATE(<name>)
dnl Expands to the command used to remove the package 'name' using the current
dnl selected package manager.
dnl If selected package manager isnt supported, would expand to an empty string
dnl 
define(ETC_PKG_REMOVE,`dnl
ifelse(ETC_PKG_MANAGER,brew,brew uninstall $1,dnl
ifelse(ETC_PKG_MANAGER,apt-get,sudo apt-get -y remove $1,dnl
ifelse(ETC_PKG_MANAGER,apt-fast,sudo apt-fast -y remove $1,dnl
ifelse(ETC_PKG_MANAGER,pip,pip uninstall $1,dnl
ifelse(ETC_PKG_MANAGER,pip3,pip3 uninstall $1)))))')

dnl Usage: ETC_PKG(<name>, [package manager])
dnl Maintain package by 'name' using the 'package manager'. If package manager
dnl is not specified, would use the current selected package manager.
dnl If the package by 'name' is not installed, would install package.
dnl If the package by 'name,' is outdated, would update package.
dnl If the remove target is called, would remove package.
dnl If the selected package manager is not installed, would expand to an empty
dnl string.
define(ETC_PKG,`dnl
ifelse(eval($# < 2),TRUE,`ETC_PKG($1,ETC_PKG_MANAGER)',dnl
ETC_PKG_SELECT($2)dnl
ETC_GEN_MAKE(ETC_SELECTION,`dnl
ETC_PKG_INSTALL($1)
ETC_MARK',
`dnl
ETC_PKG_UPDATE($1)
ETC_MARK',
`dnl
ETC_PKG_REMOVE($1)
ETC_MARK')
popdef(`ETC_PKG_MANAGER'))')

#Git
dnl Usage: ETC_GIT_RETREIVE('url', 'destination')
dnl Expand to the command retrieve the git repositiory pointed to at 'url'
dnl to the 'destination' filepath.
dnl
define(ETC_GIT_RETREIVE, `git clone $1 $2')


dnl Usage: ETC_GIT_UPDATE(path)
dnl Expands to the command used to update the git repository at 'path'
dnl
define(ETC_GIT_UPDATE, `git pull -r $1')

dnl Usage: ETC_GIT(<url>,<path>)
dnl Maintain git repositiory at path using git repositiory pointed to by 'url'
dnl 
define(ETC_GIT,`dnl
ETC_GEN_MAKE(ETC_SELECTION,`dnl
ETC_GIT_RETREIVE($1,$2)
ETC_MARK',
`dnl
ETC_GIT_UPDATE($2)
ETC_MARK',
`dnl
rm -rf $2
ETC_UNMARK')')

ifelse(`
#Autotools #TODO:test if working
#TODO: Translate macro to use ETC_GEN_MAKE
dnl Usage: ETC_AUTL_INSTALL(<path>)
dnl Expands to the commands used to install the package 'name' using Autotools
dnl from source to at 'path'
dnl 
define(ETC_AUTL_INSTALL,`dnl
pushd $1
ETC_EXTRACT_TGZ(*)
./configure
make
sudo make install
popd')

#TODO: Add support for checking last updated.

dnl Usage: ETC_AUTL_REMOVE(<path>)
dnl Expands to the commands used to remove the package 'name' using Autotools.
dnl from source to at 'path'
dnl 
define(ETC_AUTL_REMOVE, `dnl
pushd $1
make uninstall
popd
rm -rf $1')

dnl Usage: ETC_AUTL(<name>,<url>,[<path>])
dnl Maintain 'name' using Autotool source pointed to by 'url'
dnl If 'path' is not obmitted, move the source under 'path' directory
dnl If 'name' is not installed, would install 'name' from source.
dnl If 'name' update target is called, would reinstall 'name' from source
dnl If the remove target is called, would remove 'name' using source.
dnl' 
define(ETC_AUTL,`dnl
ifelse(eval($# < 3),TRUE,`ETC_AUTL($1, $2, WORK_DIR/autl-$1)',dnl
.PHONY: install update remove
install: ETC_TARGET($1)
update:
	ETC_RETRIEVE($2, `$3/$1.tgz')
	ETC_AUTL_INSTALL($3)
	ETC_MARK($1)
remove:
	ETC_AUTL_REMOVE($3)
	ETC_UNMARK($1)
ETC_TARGET($1):
	@mkdir $3
	ETC_RETRIEVE($2, `$3/$1.tgz')
	ETC_AUTL_INSTALL($3)
	ETC_MARK($1)
)')

')

#Cleanup
popdef(TRUE)
popdef(FALSE)
popdef(PERROR)
popdef(WORK_DIR)
popdef(CHOMP)
popdef(NEWLINE)
undefine(ETC_SELECTION)
undefine(ETC_PKG_MANAGER)

#Defaults
ETC_PKG_SELECT
divert(0)dnl