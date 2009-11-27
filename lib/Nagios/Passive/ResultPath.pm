package Nagios::Passive::ResultPath;

use strict;
use Carp;
use File::Temp;
use Fcntl qw/:DEFAULT :flock/;
use Moose;

extends 'Nagios::Passive::Base';

my $TEMPLATE = "cXXXXXX";

has 'checkresults_dir'    => ( is => 'ro', isa => 'Str', required => 1);
has 'check_type'          => ( is => 'rw', isa => 'Int', default => 1);
has 'check_options'       => ( is => 'rw', isa => 'Int', default => 0);
has 'scheduled_check'     => ( is => 'rw', isa => 'Int', default => 0);
has 'latency'             => ( is => 'rw', isa => 'Num', default => 0);
has 'start_time'          => ( is => 'rw', isa => 'Num', default=>time . ".0");
has 'finish_time'         => ( is => 'rw', isa => 'Num', default=>time . ".0");
has 'early_timeout'       => ( is => 'rw', isa => 'Int', default=>0);
has 'exited_ok'           => ( is => 'rw', isa => 'Int', default=>1);
has 'command_file'=>(is => 'ro', isa => 'Str', predicate=>'has_command_file' );
has 'tempfile' => ( is => 'ro', isa => 'File::Temp', lazy_build => 1);

sub BUILD {
  my $self = shift;
  my $cd = $self->checkresults_dir;
  croak("$cd is not a directory") unless(-d $cd);
};

sub _build_tempfile {
  my $self = shift;
  my $fh = File::Temp->new(
    TEMPLATE => $TEMPLATE,
    DIR => $self->checkresults_dir,
  );
  $fh->unlink_on_destroy(0);
  return $fh;
}

sub _touch_file {
  my $self = shift;
  my $fh = $self->tempfile;
  my $file = $fh->filename.".ok";
  sysopen my $t,$file,O_WRONLY|O_CREAT|O_NONBLOCK|O_NOCTTY
    or croak("Can't create $file : $!");
  close $t or croak("Can't close $file : $!");
}

sub to_string {
  my $self = shift;
  my $string = "";
  $string.="### Active Check Result File ###\n";
  $string.=sprintf "file_time=%d\n\n",$self->time;
  $string.="### Nagios Service Check Result ###\n";
  $string.=sprintf "# Time: %s\n",scalar localtime $self->time;
  $string.=sprintf "host_name=%s\n", $self->host_name;
  if(defined($self->service_description)) {
    $string.=sprintf "service_description=%s\n", $self->service_description;
  }
  $string.=sprintf "check_type=%d\n", $self->check_type;
  $string.=sprintf "check_options=%d\n", $self->check_options;
  $string.=sprintf "scheduled_check=%d\n", $self->scheduled_check;
  $string.=sprintf "latency=%f\n", $self->latency;
  $string.=sprintf "start_time=%f\n", $self->start_time;
  $string.=sprintf "finish_time=%f\n", $self->finish_time;
  $string.=sprintf "early_timeout=%d\n", $self->early_timeout;
  $string.=sprintf "exited_ok=%d\n", $self->exited_ok;
  $string.=sprintf "return_code=%d\n", $self->return_code;
  $string.=sprintf "output=%s %s - %s\n", $self->check_name, 
             $self->_status_code, $self->_quoted_output;
  return $string;
}

sub submit {
  my $self = shift;
  my $fh = $self->tempfile;
  print $fh $self->to_string;
  $self->_touch_file;
  return $fh->filename;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Nagios::Passive::ResultPath - drop check results into Nagios' check_result_path.

=head1 SYNOPSIS

  my $nw = Nagios::Passive->create(
    checkresults_dir => $checkresultsdir,
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3 
    output => 'looks (good|bad|horrible) | performancedata'
  );
  $nw->submit

=head1 DESCRIPTION

This module gives you the ability to drop checkresults directly
into Nagios' check_result_path.

The usage is described in L<Nagios::Passive>.

=cut
