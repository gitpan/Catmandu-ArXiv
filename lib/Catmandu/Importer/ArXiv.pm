package Catmandu::Importer::ArXiv;

use Catmandu::Sane;
use Moo;
use Furl;
use XML::LibXML::Simple qw(XMLin);

with 'Catmandu::Importer';


# INFO:
# http://arxiv.org/help/api/index/


# Constants. -------------------------------------------------------------------

use constant BASE_URL => 'http://export.arxiv.org/api/query';


# Properties. ------------------------------------------------------------------

# required.
has base => (is => 'ro', default => sub { return BASE_URL; });
has query => (is => 'ro', required => 1);

# optional.
has id_list => (is => 'ro');

# internal stuff.
has _currentRecordSet => (is => 'ro');
has _n => (is => 'ro', default => sub { 0 });
has _start => (is => 'ro', default => sub { 0 });
has _max_results => (is => 'ro', default => sub { 10 });


# Internal Methods. ------------------------------------------------------------

# Internal: HTTP GET something.
#
# $url - the url.
#
# Returns the raw response object.
sub _request {
  my ($self, $url) = @_;

  my $furl = Furl->new(
    agent => 'Mozilla/5.0',
    timeout => 10
  );

  my $res = $furl->get($url);
  die $res->status_line unless $res->is_success;

  return $res;
}

# Internal: Converts XML to a perl hash.
#
# $in - the raw XML input.
#
# Returns a hash representation of the given XML.
sub _hashify {
  my ($self, $in) = @_;

  my $xs = XML::LibXML::Simple->new();
  my $out = $xs->XMLin(
	  $in, 
	  KeyAttr => [], 
	  ForceArray => [ 'entry' ]
  );

  return $out;
}

# Internal: Makes a call to the arXiv API.
#
# Returns the XML response body.
sub _api_call {
  my ($self) = @_;

  # construct the url
  my $url = $self->base;
  $url .= '?search_query='.$self->query;
  $url .= '&id_list='.$self->id_list if $self->id_list;
  $url .= '&start='.$self->_start if $self->_start;
  $url .= '&max_results='.$self->_max_results if $self->_max_results;

  # http get the url.
  my $res = $self->_request($url);

  # return the response body.
  return $res->{content};
}

# Internal: gets the next set of results.
#
# Returns a array representation of the resultset.
sub _nextRecordSet {
  my ($self) = @_;
  
  # fetch the xml response and hashify it.
  my $xml = $self->_api_call;
  my $hash = $self->_hashify($xml);

  # get to the point.
  my $set = $hash->{entry};

  # return a reference to a array.
  return \@{$set};
}

# Internal: gets the next record from our current resultset.
#
# Returns a hash representation of the next record.
sub _nextRecord {
  my ($self) = @_;

  # fetch recordset if we don't have one yet.
  $self->{_currentRecordSet} = $self->_nextRecordSet unless $self->_currentRecordSet;

  # check for a exhaused recordset.
  if ($self->_n >= $self->_max_results) {
	  $self->{_currentRecordSet} = $self->_nextRecordSet;
	  $self->{_start} += $self->_max_results;
	  $self->{_n} = 0;
  }

  # return the next record.
  return $self->_currentRecordSet->[$self->{_n}++];
}


# Public Methods. --------------------------------------------------------------

sub generator {
  my ($self) = @_;

  return sub {
    $self->_nextRecord;
  };
}


# PerlDoc. ---------------------------------------------------------------------

=head1 NAME

  Catmandu::Importer::ArXiv - Package that imports arXiv data.

=head1 SYNOPSIS

  use Catmandu::Importer::ArXiv;

  my %attrs = (
    query => 'all:electron'
  );

  my $importer = Catmandu::Importer::ArXiv->new(%attrs);

  my $n = $importer->each(sub {
    my $hashref = $_[0];
    # ...
  });

=cut

=head1 SEE ALSO

L<Catmandu::Iterable>

=cut

1;
