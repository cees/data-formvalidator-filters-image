
use lib './t';

use strict;
use warnings;

use CGI;
use Config;
use File::Spec;
use Data::FormValidator;
use Data::FormValidator::Filters::Image;

# We don't use any of the standard Test modules, because I couldn't
# figure out how to get Test::More to work in a forked environment.
# Test::Harness wouldn't see any of the output, so the tests showed up
# as failed.  The old fashion way works just as well though.

$| = 1;

# test function from CGI.pm
sub test {
    local ($^W) = 0;
    my ( $num, $true, $msg ) = @_;
    print( $true ? "ok $num $msg\n" : "not ok $num $msg\n" );
}

print "1..37\n";

unless ( $Config{d_fork} ) {
    test( $_, 1, "# skip fork not available on this platform" ) for 1 .. 32;
    exit;
}
else {
    test( 1, 1, 'fork required for these tests' );
}

eval { require HTTP::Request::Common; };
if ($@) {
    test( $_, 1, "# skip HTTP::Request::Common required for these test" )
      for 2 .. 32;
    exit;
}
else {
    test( 2, 1, 'HTTP::Request::Common required for these tests' );
}

my $image_info_not_available = 0;
eval { require Image::Info; };
if ($@) {
    $image_info_not_available = 1;
}

# Create a request

# Fake a web server CGI request by building a proper
# POST request, setting some ENV variables and
# forking a child process that gets the POST
# content from STDIN
my $req = &HTTP::Request::Common::POST(
    '/dummy_location',
    Content_Type => 'form-data',
    Content      => [
        name   => 'name1',
        test   => 'name2',
        image1 => ["t/image.jpg"],
        image2 => ["t/image.jpg"],
        image3 => ["t/image.jpg"],
        image4 => ["t/image.jpg"],
        image5 => ["t/image.jpg"],
        image6 => ["t/empty.jpg"],
        image7 => ["t/image.jpg", 'C:/Program Files/dumb/filename/IE/passes.jpg'],
        file   => ["t/file.txt"],
    ]
);
$ENV{REQUEST_METHOD} = 'POST';
$ENV{CONTENT_TYPE}   = 'multipart/form-data';
$ENV{CONTENT_LENGTH} = $req->content_length;
if ( open( CHILD, "|-" ) ) {    # cparent
    print CHILD $req->content;
    close CHILD;
    exit 0;
}

# at this point, we're in a new (child) process
# and CGI.pm can read the POST params from STDIN
# as in a real request
my $q = CGI->new;

my $profile = {
    required => [qw(image1 image2 image3 image4 image5 image6 image7 file name)],
    field_filters => {
        image1 => Data::FormValidator::Filters::Image::image_filter(
            max_width  => 75,
            max_height => 50,
        ),
        image2 => Data::FormValidator::Filters::Image::image_filter(
            max_width  => 50,
            max_height => 75,
        ),
        image3 => Data::FormValidator::Filters::Image::image_filter(
            max_width => 50,
        ),
        image4 => Data::FormValidator::Filters::Image::image_filter(
            max_height => 50,
        ),
        image5 => Data::FormValidator::Filters::Image::image_filter(),
        image6 => Data::FormValidator::Filters::Image::image_filter(
            max_width  => 50,
            max_height => 50,
        ),
        image7 => Data::FormValidator::Filters::Image::image_filter(
            max_width  => 50,
            max_height => 50,
        ),
        file => Data::FormValidator::Filters::Image::image_filter(
            max_width  => 50,
            max_height => 50,
        ),
        name => Data::FormValidator::Filters::Image::image_filter(
            max_width  => 50,
            max_height => 50,
        ),
    },
};

my $results = Data::FormValidator->check( $q, $profile );

test( 3, $results, "Data::FormValidator check" );

my $valid = $results->valid;

{
    # Test Image #1
    #
    #            max_width  => 75,
    #            max_height => 50,
    #
    my $fh = $valid->{image1};

    test( 4, ref $fh eq 'Fh', "valid Fh object" );

    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    $filename = File::Spec->catdir( 't', 'sh_' . $filename );
    unlink $filename if -e $filename;
    if ($fh) {
        open( my $newfh, '>', $filename )
            || die "Can't open temp image filename $filename";
        my $buffer;
        while ( sysread $fh, $buffer, 4096 ) {
            print $newfh $buffer;
        }
        close $newfh;
    }

    test( 5, -e $filename, "Temporary image saved" );

    if ($image_info_not_available) {
        test( $_, 1, "# skip Image::Info required for these test" ) for 6 .. 8;
    }
    else {
        my $info = Image::Info::image_info($filename);
        test( 6, !$info->{error}, "Image::Info results" );
        my ( $w, $h ) = Image::Info::dim($info);
        test( 7, $info->{width} == 37, "Width is 37" );
        test( 8, $info->{height} == 50, "Height is 50" );
    }
    unlink $filename if -e $filename;
}

{
    # Test Image #2
    #
    #            max_width  => 50,
    #            max_height => 75,
    #
    my $fh = $valid->{image2};

    test( 9, ref $fh eq 'Fh', "valid Fh object" );

    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    $filename = File::Spec->catdir( 't', 'sh_' . $filename );
    unlink $filename if -e $filename;
    if ($fh) {
        open( my $newfh, '>', $filename )
            || die "Can't open temp image filename $filename";
        my $buffer;
        while ( sysread $fh, $buffer, 4096 ) {
            print $newfh $buffer;
        }
        close $newfh;
    }

    test( 10, -e $filename, "Temporary image saved" );

    if ($image_info_not_available) {
        test( $_, 1, "# skip Image::Info required for these test" ) for 11 .. 13;
    }
    else {
        my $info = Image::Info::image_info($filename);
        test( 11, !$info->{error}, "Image::Info results" );
        my ( $w, $h ) = Image::Info::dim($info);
        test( 12, $info->{width} == 50, "Width is 50" );
        test( 13, $info->{height} == 66, "Height is 66" );
    }
    unlink $filename if -e $filename;
}

{
    # Test Image #3
    #
    #            max_width  => 50,
    #
    my $fh = $valid->{image3};

    test( 14, ref $fh eq 'Fh', "valid Fh object" );

    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    $filename = File::Spec->catdir( 't', 'sh_' . $filename );
    unlink $filename if -e $filename;
    if ($fh) {
        open( my $newfh, '>', $filename )
            || die "Can't open temp image filename $filename";
        my $buffer;
        while ( sysread $fh, $buffer, 4096 ) {
            print $newfh $buffer;
        }
        close $newfh;
    }

    test( 15, -e $filename, "Temporary image saved" );

    if ($image_info_not_available) {
        test( $_, 1, "# skip Image::Info required for these test" ) for 16 .. 18;
    }
    else {
        my $info = Image::Info::image_info($filename);
        test( 16, !$info->{error}, "Image::Info results" );
        my ( $w, $h ) = Image::Info::dim($info);
        test( 17, $info->{width} == 50, "Width is 50" );
        test( 18, $info->{height} == 66, "Height is 66" );
    }
    unlink $filename if -e $filename;
}

{
    # Test Image #4
    #
    #            max_height  => 50,
    #
    my $fh = $valid->{image4};

    test( 19, ref $fh eq 'Fh', "valid Fh object" );

    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    $filename = File::Spec->catdir( 't', 'sh_' . $filename );
    unlink $filename if -e $filename;
    if ($fh) {
        open( my $newfh, '>', $filename )
            || die "Can't open temp image filename $filename";
        my $buffer;
        while ( sysread $fh, $buffer, 4096 ) {
            print $newfh $buffer;
        }
        close $newfh;
    }

    test( 20, -e $filename, "Temporary image saved" );

    if ($image_info_not_available) {
        test( $_, 1, "# skip Image::Info required for these test" ) for 21 .. 23;
    }
    else {
        my $info = Image::Info::image_info($filename);
        test( 21, !$info->{error}, "Image::Info results" );
        my ( $w, $h ) = Image::Info::dim($info);
        test( 22, $info->{width} == 37, "Width is 37" );
        test( 23, $info->{height} == 50, "Height is 50" );
    }
    unlink $filename if -e $filename;
}

{
    # Test Image #5
    #
    #
    my $fh = $valid->{image5};

    test( 24, ref $fh eq 'Fh', "valid Fh object" );

    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    $filename = File::Spec->catdir( 't', 'sh_' . $filename );
    unlink $filename if -e $filename;
    if ($fh) {
        open( my $newfh, '>', $filename )
            || die "Can't open temp image filename $filename";
        my $buffer;
        while ( sysread $fh, $buffer, 4096 ) {
            print $newfh $buffer;
        }
        close $newfh;
    }

    test( 25, -e $filename, "Temporary image saved" );

    if ($image_info_not_available) {
        test( $_, 1, "# skip Image::Info required for these test" ) for 26 .. 28;
    }
    else {
        my $info = Image::Info::image_info($filename);
        test( 26, !$info->{error}, "Image::Info results" );
        my ( $w, $h ) = Image::Info::dim($info);
        test( 27, $info->{width} == 75, "Width is 50" );
        test( 28, $info->{height} == 100, "Height is 66" );
    }
    unlink $filename if -e $filename;
}

{
    # Test Image #6
    #
    # Run the image_filter over an invalid (empty) image file
    #
    my $fh = $valid->{image6};
    test( 29, ref $fh eq 'Fh', "valid Fh object" );
}

{
    # Test Image #7
    #
    #            max_width  => 50,
    #            max_height => 50,
    #  with a Microsoft IE style path
    #
    my $fh = $valid->{image7};

    test( 30, ref $fh eq 'Fh', "valid Fh object" );

    my $filename = $fh->asString;
    $filename =~ s/^.*[\/\\]//; # strip off any path information that IE puts in the filename
    $filename = File::Spec->catdir( 't', 'sh_' . $filename );
    unlink $filename if -e $filename;
    if ($fh) {
        open( my $newfh, '>', $filename )
            || die "Can't open temp image filename $filename";
        my $buffer;
        while ( sysread $fh, $buffer, 4096 ) {
            print $newfh $buffer;
        }
        close $newfh;
    }

    test( 31, -e $filename, "Temporary image saved" );

    if ($image_info_not_available) {
        test( $_, 1, "# skip Image::Info required for these test" ) for 32 .. 35;
    }
    else {
        my $info = Image::Info::image_info($filename);
        test( 32, !$info->{error}, "Image::Info results" );
        my ( $w, $h ) = Image::Info::dim($info);
        test( 33, $info->{width} == 37, "Width is 37" );
        test( 34, $info->{height} == 50, "Height is 50" );
    }
    unlink $filename if -e $filename;
}

{
    # Test File
    #
    # Run the image_filter of a text file
    #
    my $fh = $valid->{file};

    test( 35, ref $fh eq 'Fh', "valid Fh object" );

    my @lines = <$fh>;
    chomp $lines[0];
    test(
        36,
        $lines[0] eq 'This is a dummy file',
        "Text file wasn't clobbered"
    );
}

{
    # Test 'name' field
    #
    # We ran the image_filter over a value that was just a plain string
    test( 37, $valid->{name} eq 'name1', "Data::FormValidator check" );
}
