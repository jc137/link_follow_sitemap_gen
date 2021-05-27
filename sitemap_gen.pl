#! /usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $base_url = shift(@ARGV);
our @link_list = ();

$base_url =~ s|#.+$||gm;
$base_url =~ s|/+$||gm;
add_link($base_url);
follow_link($base_url);

sub follow_link {
	my $link = shift;
	print $link . "\n";
	my $html = fetch_url_content($link);
	if ($html)
	{
		while ($html =~ m|<a.*?href="([^"]+)"|gm)
		{
			if ($1)
			{
				next if $1 =~ m/http/;
				my $link = sprintf('%s/%s', $base_url, $1);
				$link =~ s|#.+$||gm;
				$link =~ s|/+$||gm;
				$link =~ s|\.\.||gm;
				$link =~ s|/+|/|gm;
				$link =~ s|http:/|http://|gm;
				if(add_link($link))
				{
					follow_link($link);
				}
			}
		}
	}
	else
	{
		print "failed\n";
	}
}

print "generating sitemap\n";

my $template_content = '';
if (open(my $fh, '<', 'sitemap.tmpl'))
{
	while (<$fh>)
	{
		$template_content .= $_;
	}
	close($fh);
}


my $today = `date "+%Y-%m-%d"`;
chomp($today);

foreach my $link (@link_list)
{
	my $entry = '<url>
<loc>' . $link . '</loc>
<lastmod>' . $today . '</lastmod>
</url>
<url>';
	$template_content =~ s|##PLCH##|${entry}##PLCH##|gm;
}

$template_content =~ s|##PLCH##||gm;

print $template_content;

sub add_link {
	my $link = shift;
	unless ( grep { $_ eq $link } @link_list)
	{
		push @link_list, $link;
		return 1;
	}
	return 0;
}

sub fetch_url_content {
	my $url = shift;

	my $request_tool = _find_request_binary();

	if ($request_tool)
	{
		my $cmd = sprintf('%s \'%s\' 2> /dev/null', http_get_cmd($request_tool), $url);
		my $html = `$cmd`;
		chomp($html);
		return $html;
	}
	else
	{
		die('no request_tool found');
	}
	return;
}

sub http_get_cmd {
	my $tool = shift;
	if ($tool =~ m/wget/)
	{
		return sprintf('%s -O-', $tool);
	}
	else
	{
		return $tool;
	}
	return;
}

sub _find_request_binary 
{
	my @binarys = qw|curl wget|;
	my $return = undef;
	foreach my $bin (@binarys)
	{
		my $shel_out = `which $bin`;
		chomp($shel_out);
		next unless $shel_out;
		if (-x $shel_out)
		{
			$return = $shel_out;
			last;
		}
	}
	return $return;
}
