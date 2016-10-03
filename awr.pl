#!/bin/env perl

use strict;
use warnings;
use DBI;
use DBD::Oracle qw(:ora_session_modes);
use Getopt::Long;

my $dbhost = undef;
my $dbuser = undef;
my $dbpass = undef;
my $dbconn = undef;
my $inst_id= 1;
my $dba    = undef;

my $sid =  $ENV{'ORACLE_SID'};


my $begin       = -1;
my $end         = -1;
my $begin2      = -1;
my $end2        = -1;
my $begin_date  = '';
my $end_date    = '';
my $begin_date2 = '';
my $end_date2   = '';
my $o_file      = "output.html";
my $usage;
my $global;
my $text;
my $verbose     = '';

my $usage_txt = qq{
awr.pl -- A perl wrapper for AWR Report. (C) 2016 Max Lambertini (m.lambertini\@gmail.com)

USAGE: ./awr.pl [options]
    -u, --dbuser=[user]  : Oracle user
    -p, --dbpass=[pass]  : Oracle password
    -n, --dbinst=[num]   : DB Instance (default = 1)
    -h, --dbhost=[host]  : TNS Alias, if needed
    -s, --begin=[num]    : starting awr snapshot id
    -b, --begind=[date]  : begin interval date
    -f, --end=[num]      : ending awr snapshot id
    -e, --endd=[date]    : end interval date
    -c, --begind2=[date] : begin 2nd interval date (for awr comparison)
    -k, --endd2=[date]   : end 2nd interval date (for awr comparison)

    NOTE: Dates must comply to this mask: YYYYMMDD_HH24:MI:SS. For instance, 20160920_19:34:41
    
    -o, --output[fname]  : output filename. A standard filename will be generated if empty
    
    Flags:
    
    -a, --dba            : connect as sysdba
    -G, --global         : when generating reports on a RAC, generates a global report
    -t, --text           : generate a text report instead of an HTML one
    -h, --help           : show this screen
    
Sample usage:

Generate an awr report between two dates as sysba 
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 

Same report in a text format
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 --text
    
Same report on rac instance 2
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 --dbinst=2
    
Same date interval, global RAC report
 awr.pl --dba --begind=20160927_11:50:00 --endd=20160927_14:15:00 --global
    
Same report using system user, specifiying a tnsnames alias and a custom output file
 awr.pl --begind=20160927_11:50:00 --endd=20160927_14:15:00 --dbuser=system --dbpass=Password01 --dbhost=ORA12 --output=custom.html
    
};



  
GetOptions("begin|s=i"  => \$begin,
           "begin2|z=i" => \$begin2,
           "begind|b=s" => \$begin_date,
           "begind2|c=s"=> \$begin_date2,
           "endd|e=s"   => \$end_date,
           "endd2|k=s"  => \$end_date2,
           "end|f=i"    => \$end,
           "end2|j=i"   => \$end2,
           "dbuser|u=s" => \$dbuser,
           "dbpass|p=s" => \$dbpass,
           "dbinst|n=i" => \$inst_id,
	       "dbhost|h=s" => \$dbhost,
           "output|o=s" => \$o_file,
           "dba|a"      => \$dba,
           "global|g"   => \$global,
           "text|t"     => \$text,
           "verbose|v"  => \$verbose,
           "help|h"     => \$usage)
or die ("Error in command line argument. awr.pl --help for usage info \n");

if ($verbose) {
	my $dump = qq(
Parameters passed:
--------------------------------------------------
Begin Snapshot..........: $begin
Begin Snapshot2.........: $begin2
Begin Date..............: $begin_date
Begin Date 2............: $begin_date2
End Date................: $end_date
End Date 2..............: $end_date2
End Snapshot............: $end
End Snapshot2...........: $end2
DB User.................: $dbuser
DB Pass.................: $dbpass
DB Inst.................: $inst_id
DB Host.................: $dbhost
Outout..................: $o_file
Sysdba..................: $dba
Global report...........: $global
Text mode...............: $text
Verbose mode............: $verbose
Help....................: $usage
--------------------------------------------------

);
	print "$dump\n";
}

# if true, then generate awr report compare
if ($text) { $text="text"; } else { $text="html"; }

if ($usage) {
        print $usage_txt;
        die("\n");
}

$dbhost = $dbhost eq '' ? "dbi:Oracle:" : "dbi:Oracle:" . $dbhost;

print "Host is $dbhost\n";

my $dbh;
if ($dba) {
    $dbh = DBI->connect(
      $dbhost,
      $dbuser,
      $dbpass,
      { ora_session_mode => ORA_SYSDBA }
    );
} else {
    $dbh = DBI->connect(
      $dbhost,
      $dbuser,
      $dbpass);
}

if ($dbh) {
  print "Connected\n";
} else {
  die $DBI::errstr;
}

my @data;
my $sth1 = $dbh->prepare ("select dbid from v\$database") or die ("Cannot get DBID\n");
$sth1->execute();
@data = $sth1->fetchrow_array();
my $dbid  = $data[0];
$sth1->finish();

print "DB ID is $dbid\n";

if ($begin == -1 || $end == -1)  {
        $sth1 = $dbh->prepare ("select max(snap_id) from dba_hist_snapshot") or die ("Cannot get Snap id\n");
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end = $data[0];
        $begin = $end-1;
        $sth1->finish();
}

if ($begin_date && $end_date) {
        my $the_sql = qq{
                select a.begin_snap, b.end_snap
                from (select max(snap_id) begin_snap
          from dba_hist_snapshot
                 where begin_interval_time <= to_date('$begin_date','YYYYMMDD_HH24:MI:SS')) a,
                (select min(snap_id) end_snap
          from dba_hist_snapshot
                 where end_interval_time >= to_date('$end_date','YYYYMMDD_HH24:MI:SS')) b
        };
		if ($verbose) { 
			print "snap id from date:\n$the_sql\n\n";
		}
        $sth1 = $dbh->prepare ($the_sql);
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end = $data[1];
        $begin = $data[0];
        $sth1->finish();
}


if ($begin_date2 && $end_date2) {
        my $the_sql = qq{
                select a.begin_snap, b.end_snap
                from (select max(snap_id) begin_snap
          from dba_hist_snapshot
                 where begin_interval_time <= to_date('$begin_date2','YYYYMMDD_HH24:MI:SS')) a,
                (select min(snap_id) end_snap
          from dba_hist_snapshot
                 where end_interval_time >= to_date('$end_date2','YYYYMMDD_HH24:MI:SS')) b
        };

		if ($verbose) { 
			print "snap id from date:\n$the_sql\n\n";
		}
        $sth1 = $dbh->prepare ($the_sql);
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end2 = $data[1];
        $begin2 = $data[0];
        $sth1->finish();
}


if ($begin == -1 || $end == -1)  {
        $sth1 = $dbh->prepare ("select max(snap_id) from dba_hist_snapshot") or die ("Cannot get Snap id\n");
        $sth1->execute();
        @data = $sth1->fetchrow_array();
        $end = $data[0];
        $begin = $end-1;
        $sth1->finish();
}

my $compare_reports = ($begin2 != -1 && $end2 != -1);


if (!$compare_reports) {
    if ( ($begin != -1 && $end != -1) && ($o_file eq "output.html"))
    {
        if (!$global) {
            $o_file = "awr_".$inst_id."_".$sid."_".$begin."_".$end.".".$text;
        } else {
            $o_file = "awrg_".$inst_id."_".$sid."_".$begin."_".$end.".".$text;
        }     
    }
} else {
    if (!$global) {
        $o_file = "awr_c_".$inst_id."_".$sid."_".$begin."_".$end."_".$begin2."_".$end2.".".$text;
    } else {
        $o_file = "awrg_c_".$inst_id."_".$sid."_".$begin."_".$end."_".$begin2."_".$end2.".".$text;
    }     
}    


my $sql;
if (!$compare_reports) {
    if ($global) {
         $sql = "select output from table(dbms_workload_repository.awr_global_report_$text ('$dbid','',$begin,$end))";
        print "$sql\n";
    } else {
        $sql = "select output from table(dbms_workload_repository.awr_report_$text ('$dbid',$inst_id,$begin,$end))";
    }   
} else {
    if ($global) {
         $sql = "select output from table(dbms_workload_repository.awr_global_diff_report_$text ('$dbid','',$begin,$end,$dbid,'', $begin2, $end2))";
        print "$sql\n";
    } else {
        $sql = "select output from table(dbms_workload_repository.awr_diff_report_$text ($dbid,$inst_id,$begin,$end,$dbid,$inst_id, $begin2, $end2))";
    }   
}

print "Writing snapshot data from $begin to $end on $o_file\n\n";

$sth1 = $dbh->prepare ($sql);
$sth1->execute();
my $output = "";
my $f;  open ($f,">", $o_file) or die ("Cannot create file $o_file\n");
while (@data = $sth1->fetchrow_array()) {
        $output = $data[0];
        print $f "$output\n" if ($output);
}


$dbh->disconnect;
print "<!-- that's all -->\n";



