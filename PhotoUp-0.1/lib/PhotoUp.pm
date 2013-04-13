package PhotoUp;

# ABSTRACT: Upload and email photo(s) demo using ssmpt and Hotmail
use Dancer2;
use Dancer2::Core::Error;

our $VERSION = '0.1';

use Template;
use Data::Dump qw/dump/;
use Carp qw/croak/;
use Try::Tiny;
use IO::All;
use File::LibMagic;

#------Email
use Email::Valid;
use Email::Sender::Simple qw(sendmail);
use MIME::Entity;
use Email::Sender::Transport::SMTP::TLS;

#------ Globals
my $file_upload_route    = '/photo_upload';
my $uploaded_file        = 'inPhoto';
my $email_to             = 'emailTo';
my $image_file_suffix_rx = qr/\.(gif|png|jpe?g)$/;
my $image_file_type_rx   = qr/image\/(jpeg|gif|png)/;


get $file_upload_route => sub {
    debug 'Got to GET photo_upload page';

    #------ Render the upload page.
    template 'photo_upload.tt', { title => 'Upload Photos', };
};


post $file_upload_route => sub {
    debug 'Got to POST photo_upload page';

    debug "Params are : " . dump( request->params );
    my $validation_results = {
        in_photo => upload($uploaded_file) // undef,
        email_to => params->{$email_to},
    };

    _validate_user_input($validation_results);
    debug 'These are the validation results: ' . dump($validation_results);

    #------ Display errors
    if (   ( exists $validation_results->{email_error} )
        or ( exists $validation_results->{upload_error} ) )
    {
        debug 'Got to display some Errors.';
        return template 'photo_upload.tt', {
            title => 'Upload Photo Errors',
            %$validation_results,
            warning_message => 'You must upload the file again and enter a
            correct email address!',
        };
    }

    debug 'Good, passed the error checks.';
    my $in_photo = $validation_results->{in_photo};

    #------ Rename the Base of the temporary file to the original File Base
    my $photo_fq_name = _rename_uploaded_file($in_photo);

    my $message = _build_email_message(
        {
            email_to => $validation_results->{email_to},
            type     => $in_photo->type,
            path     => $photo_fq_name,
            encoding => 'base64',
        }
    );

    return _process_error('Unable to build MIME::Entity')
      unless $message;

    my $transport = _build_email_transport();

    return _process_error('Unable to build Email transport!')
      unless $transport;

    # ----- Disable temporarly
    _send_email_msg( $message, $transport );

    template 'photo_sent.tt',
      {
        title              => 'Emailed Photos',
        sent_files_heading => 'Emailed Photo(s)',
        success_message    => $in_photo->basename
          . ' was emailed to '
          . $validation_results->{email_to},
        in_photos   => [$in_photo],
        have_photos => ( $in_photo ? 1 : 0 ),
        return_to   => uri_for($file_upload_route),
      };

};


sub _validate_user_input {
    my $validation_report = shift;

    if ( defined $validation_report->{in_photo} ) {
        debug 'At least there is a file uploaded.';

        #------ Check that the file is a valid Image or Photo
        $validation_report->{upload_error} = 'Not a valid photo or image type!'
          unless _validate_file( $validation_report->{in_photo} );
    }
    else {
        $validation_report->{upload_error} = 'No photo uploaded!';
    }

    #------ Validate the 'to' Email Address
    $validation_report->{email_error} = 'Invalid or no email address entered!'
      unless ( $validation_report->{email_to} =
        _validate_email_address( $validation_report->{email_to} ) );
}


sub _validate_email_address {
    my $email_address_in = shift;
    my $valid_email_addr;
    try {
        $valid_email_addr = Email::Valid->address($email_address_in);
    }
    catch {
        error 'Problems with Email::Valid!: ' . $_;
    };
    return $valid_email_addr;
}


sub _validate_file {
    my $in_file = shift;
    return
      unless ( $in_file
        && ( lc( $in_file->basename ) =~ /$image_file_suffix_rx/ )
        && ( $in_file->size <= config->{InputFile}{max_file_size} ) );
    my $FileMagic;
    try {
        $FileMagic = File::LibMagic->new();
    }
    catch {
        error $_;
    };
    return $in_file
      if ( $FileMagic->checktype_filename( $in_file->tempname ) =~
        /$image_file_type_rx/ );
}


sub _rename_uploaded_file {
    my $file_upload = shift;
    my $io_photo    = io( $file_upload->tempname );
    my $filepath    = $io_photo->filepath;
    return $io_photo->rename( $filepath . $file_upload->basename );
}


sub _build_email_message {
    my $in_photo_details = shift;
    my $data_message     = 'Files are attached!';

    #----- Follow this link for mime-types-list
    #      http://www.freeformatter.com/mime-types-list.html
    my %headers = (
        type    => "multipart/mixed",
        From    => config->{'Email'}{from},
        To      => $in_photo_details->{email_to},
        Subject => config->{'Email'}{subject} // 'Here is your photo',
    );

    my $message = try {
        MIME::Entity->build(
            Charset  => 'utf-8',
            Encoding => 'quoted-printable',
            %headers,
            Data => $data_message,
        );
    }
    catch {
        error 'Unable to build MIME::Entity! ' . $_;
        undef;
    };

    return unless $message;

    #--- Attach the photo
    $message->attach(
        Disposition => "attachment",
        type        => $in_photo_details->{type},
        Path        => $in_photo_details->{path},
        Encoding    => $in_photo_details->{encoding}
    ) if $message;

    return $message;
}


sub _build_email_transport {
    my $transport;
    my $error_msg;

    if ( config->{Email}{transport} eq q/SMTP-TLS/ ) {

        $transport = try {
            Email::Sender::Transport::SMTP::TLS->new(
                host     => config->{'Email'}{'SMTP-TLS'}{host},
                port     => config->{'Email'}{'SMTP-TLS'}{port},
                username => config->{'Email'}{'SMTP-TLS'}{username},
                password => config->{'Email'}{'SMTP-TLS'}{password}
            );
        }
        catch {
            error 'Unable to create a transport method! ' . $_;
            undef;
        };
    }
    else {
        error
"No Email transport method specified.\n Did you plan to hand deliver it?";
    }

    return $transport;
}


sub _send_email_msg {
    my $message   = shift;
    my $transport = shift;

    try {
        sendmail( $message, { transport => $transport } );
    }
    catch {
        error 'Unable to email the files!' . $_;
    };
}

#-------------------------------------------------------------------------------
#  Render Error Page
#  Pass a message and a URL to return to.
#-------------------------------------------------------------------------------
sub _process_error {
    my $error_msg = shift // 'Something really bad must have happened.';
    error $error_msg;
    return Dancer2::Core::Error->new(
        response => response(),
        status   => 500,
        message  => $error_msg,
    )->throw;
}

#-------------------------------------------------------------------------------
1

__END__

=pod

=cut