# export ORACLE_HOME=/u01/app/oracle/product/11.1.0/db_1
echo ORACLE_HOME set to $ORACLE_HOME

PATH=$ORACLE_HOME/perl/bin:$PATH
export PATH

LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$ORACLE_HOME/lib:\
$ORACLE_HOME/network/lib32:$ORACLE_HOME/network/lib:\
$ORACLE_HOME/perl/lib
export LD_LIBRARY_PATH

JAVA_HOME=$ORACLE_HOME/jdk          ; export JAVA_HOME
JRE_HOME=$ORACLE_HOME/jdk/jre       ; export JRE_HOME
PERL_BIN=$ORACLE_HOME/perl/bin      ; export PERL_BIN
PERL_HOME=$ORACLE_HOME/perl         ; export PERL_HOME

PERL5LIB_NATIVE=$ORACLE_HOME/perl/lib:$ORACLE_HOME/perl/lib/site_perl:\
$ORACLE_HOME/perl/lib/5.8.3
export PERL5LIB_NATIVE

PERL5LIB=$PERL5LIB_NATIVE; export PERL5LIB

PERL5LIB_TMP=${PERL5LIB_NATIVE}:$ORACLE_HOME/perl/libwww-perl/lib:\
$ORACLE_HOME/perl/ext/POSIX:$ORACLE_HOME/perl/URI:\
$ORACLE_HOME/perl/HTML_Parser:$ORACLE_HOME/perl/HTML-Parser/lib
export PERL5LIB_TMP 






