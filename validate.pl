#!/usr/bin/perl
# Check entries.json before pushing.  perl validate.pl
#
# Written because the real risk here is a record going quietly missing or
# landing in the wrong half, which is invisible in a 159-entry file and was
# how eleven entries were nearly lost when two data files drifted apart.
use strict; use warnings; use JSON::PP;
binmode(STDOUT, ":encoding(UTF-8)");

my $file = shift || "entries.json";
my (@err, @warn);
sub err  { push @err,  $_[0] }
sub warn_ { push @warn, $_[0] }

my $raw = do { local $/; open my $f, "<:raw", $file or die "$file: $!\n"; <$f> };
my $d = eval { JSON::PP->new->utf8->decode($raw) };
die "FAIL: $file is not valid JSON\n  $@" if $@;
die "FAIL: $file is not an array\n" unless ref $d eq 'ARRAY';

my %VOCAB = (
  category => [qw(policy politics media event)],
  level    => [qw(federal state movement)],
  stance   => ['advancing', 'opposing', 'neutral', ''],
  themes   => [qw(pesticides toxics food foodaccess healthcare medication vaccines vectors illness)],
);
my %ok = map { my $k = $_; ($k => { map { $_ => 1 } @{$VOCAB{$k}} }) } keys %VOCAB;
my @REQUIRED = qw(id date dateLabel title description category level stance);
my @POLICY_ONLY = qw(enacted actorD actorR bipartisan);

sub is_gov { my $e = shift;
  ($e->{category}//'') eq 'policy' && (($e->{level}//'') eq 'federal' || ($e->{level}//'') eq 'state') }

my (%seen_id, %by_norm, $gov, $mov);
sub norm { my $s = lc($_[0] // ''); $s =~ s/[^a-z0-9 ]/ /g; $s =~ s/\s+/ /g; $s =~ s/^ | $//g; $s }

for my $e (@$d) {
  my $id = $e->{id} // '(no id)';
  err("$id: duplicate id")                     if $seen_id{$id}++;
  for my $f (@REQUIRED) {
    err("$id: missing required field '$f'") unless defined $e->{$f};
  }
  for my $f (qw(category level stance)) {
    my $v = $e->{$f};
    err("$id: $f = '" . (defined $v ? $v : 'undef') . "' is not a known value")
      if defined $v && !$ok{$f}{$v};
  }
  for my $t (@{ $e->{themes} || [] }) {
    err("$id: theme '$t' is not a known value") unless $ok{themes}{$t};
  }
  # Dates may be YYYY, YYYY-MM or YYYY-MM-DD: a third of the record is only
  # known to the month, and the file says so rather than inventing a day.
  if (($e->{date} // '') !~ /^\d{4}(-\d{2}(-\d{2})?)?$/) {
    err("$id: date '" . ($e->{date}//'') . "' is not YYYY, YYYY-MM or YYYY-MM-DD");
  } elsif (($e->{dateLabel} // '') =~ /(\d{4})/ && $1 ne substr($e->{date}, 0, 4)) {
    err("$id: date " . $e->{date} . " and dateLabel '" . $e->{dateLabel} . "' disagree on the year");
  }
  # the two halves of the file
  if (is_gov($e)) {
    $gov++;
    err("$id: enacted policy with no position on health") if ($e->{stance}//'') eq '';
  } else {
    $mov++;
    err("$id: not policy, but carries stance '" . $e->{stance} . "'") if ($e->{stance}//'') ne '';
    for my $f (@POLICY_ONLY) {
      err("$id: not policy, but carries '$f'") if defined $e->{$f};
    }
  }
  # sources should be {label,url} or a plain string, never half of one
  for my $s (@{ $e->{sources} || [] }) {
    next unless ref $s eq 'HASH';
    err("$id: a source has a url but no label") if $s->{url} && !$s->{label};
    err("$id: a source has a label but no url") if $s->{label} && !$s->{url};
  }
  warn_("$id: no link and no sources") unless ($e->{link}//'') ne '' || @{ $e->{sources} || [] };
  push @{ $by_norm{ norm(substr($e->{title}//'', 0, 46)) } }, $id;
}

# near-duplicate titles, the way the five merged pairs got in
for my $k (sort keys %by_norm) {
  my @ids = @{ $by_norm{$k} };
  warn_("possible duplicate: " . join(", ", @ids) . " share a title opening") if @ids > 1;
}

# sorted newest first, which the page relies on
my $prev;
for my $e (@$d) {
  my $dt = $e->{date} // '';
  err(($e->{id}//'?') . ": out of order, $dt follows $prev") if defined $prev && $dt gt $prev;
  $prev = $dt;
}

printf "%s: %d entries \x{2014} %d policy, %d movement\n", $file, scalar @$d, $gov // 0, $mov // 0;
print "\n" . scalar(@err) . " error(s)\n";
print "  \x{2717} $_\n" for @err;
print "\n" . scalar(@warn) . " warning(s)\n";
print "  ! $_\n" for @warn;
print "\n", (@err ? "FAIL\n" : "OK\n");
exit(@err ? 1 : 0);
