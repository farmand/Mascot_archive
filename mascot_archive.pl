#! /usr/bin/perl -w
use strict;

# additional packages
use Getopt::Long;
use File::Basename;

#######################################
# get the command line parameters
#######################################
my $in;
my $out;
my $min_size = 5000; # size in MB

# the message sent when parameters are wrong
my $failed_message = <<MESSAGE;
Invalid parameter usage:
./mascot_archive.pl -i MASCOT_RES_DIR -o OUT_DIR -s 5000 [optional-argument]
MESSAGE

GetOptions ("in=s" => \$in,
			"out=s" => \$out,
			"size=i" => \$min_size,
	) or die($failed_message);

# die if parameters are invalid
die($failed_message) unless $in and $out and -d $in and -d $out;

#######################################
# Main
#######################################
my @contents = read_dir($in);
my @current_list;
my $current_size;
my $id = 1;

for my $fi (@contents){
 	push @current_list, $fi->{path};
 	$current_size += $fi->{size};

 	if($current_size > $min_size){
 		my $tmp_el;
 		my $tmp_size = 0;

 		# remove the last entry if it's more than 1
 		if(scalar @current_list > 1){
   		$tmp_el = pop @current_list;
   		$tmp_size = $fi->{size};
   	}

 		# create the tar
 		my $tar_answer = create_tar(\@current_list, basename($in), $out, $id++);
 		print($tar_answer, "\n");
    
 		# add back the removed element or an empty list
 		@current_list = ($tmp_el)?($tmp_el):();
 		$current_size = $tmp_size;
 	}

}

my $tar_answer = create_tar(\@current_list, basename($in), $out, $id);
print($tar_answer, "\n");


#######################################
# Subroutines
#######################################

# Create tar file from selected files
sub create_tar {
	my ($ra_files, $basename, $out, $id) = @_;
	my $tar_str;

	# execute the tar compression
	my $filename = $out.'/'.$basename.'_'.$id.'.tar.gz';
	my $command = "tar czvf $filename ".join(' ', @$ra_files);
	die "failed executing [".$command."]\n" if system($command) != 0;

	# contruct the answer
	my $answer;
	foreach(@$ra_files){
		$answer .= "$filename => $_\n";
	}
	chomp($answer);
	return $answer;
}


# Takes a dir path.
# Returns a list of file_info() hash refs.
sub read_dir {
    my $d = shift;
    opendir(my $dh, $d) or die $!;
    return map  { file_info($_) }  # Collect info.
           map  { "$d/$_" }        # Attach dir path.
           grep { ! /^\.\.?$/ }    # No dot dirs.
           readdir($dh);
}


# Takes a path to a file/dir.
# Returns hash ref containing the path plus any stat() info you need.
sub file_info {
    my $f = shift;
    my @s = stat($f);
    return {
        path  => $f,
        size => int($s[7] / 1000000), # in MB
    };
}