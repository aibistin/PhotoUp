=method get $file_upload_route
  Render the file upload form.

=method post $file_upload_route
  Upload the photograph or image file. Will accept files of type .jpg, .jpeg, 
  .png, .gif.
  Validates the file type and size.
  Will email them to the user provided email address.

=method _validate_user_input
 Validate the uploaded file and the 'to' Email address.
 Pass a HashRef with the Dancer Request Upload Object and
 the email address.
 Populates the HashRef with validation information.
 {
    in_photo  =>  # the Dancer Request Upload object or not exists
    email_to => email@emails.com or not exists if invalid
    upload_error =>  'Error Msg....'  or not exists if ok
    email_error =>  'Error Msg....'  or not exists if ok
 }

=method _validate_email_address
  Validates a given Email Address.
  Uses Email::Valid
  Returns undef if not valid.

=method _validate_file 
  Validate the file type by first checking the file suffix,
  then validating the file type with File::Lib::Magic
  Also checks that the file is smaller than the maximum allowed 
  size from the config file.
  Returns the validated file or undef.

=method _rename_uploaded_file
 Renames the temporary file basename back to its original name.

=method _build_email_message
 Build the Email message
 Uses data fron the config file to populate most of these fields.

=method _build_email_transport
  Build the Email Transport. Config file specifies SMTP-TLS for this project.
  My laptop is configured to use sSmtp.
  My development configuration file has set smtp.live.com(hotmail) as the
  Email host for convenience.

=method _send_email_msg
  Send the Email with the photo attached
  Pass the message and the transport.

=head1 NAME
 
 PhotoUp - Upload and Email Photo(s) Demo
  
=head1 VERSION

Version 0.01


=head1 SYNOPSIS
        Just a demo.                                         

=head1 DESCRIPTION
  This is just a short demo to Upload a use inputted photograph or image. The
  photo will be emailed to a user inputted email address using Dancer2. It will take
  advantage or Bootstrap's photo upload and preview JavaScript/jQuery
  component. It will also use Template::Toolkit.

=head1 SEE ALSO

=over

 
=item *
 
 L<Dancer>

=item *
 
 L<Template::Toolkit>
  
=item *

 L<Email::Sender>

=back

=head1 AUTHOR

Austin Kenny, C<< <aibistin.cionnaith at gmail.com> >>


=head1 ACKNOWLEDGEMENTS
       All CPAN Contributers

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Austin Kenny.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


