#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use B::Deparse;
use Template;
use Getopt::Long;
use CGI;

use Class::MOP;

my $stand_alone = 0;
GetOptions("s" => \$stand_alone);

if ($stand_alone) {
    require HTTP::Server::Simple::CGI;
    {
        package # hide me from PAUSE
            Class::MOP::Browser::Server;
        our @ISA = qw(HTTP::Server::Simple::CGI);
        sub handle_request { ::process_template() }
    }
    Class::MOP::Browser::Server->new()->run();
}
else {
    print CGI::header();
    process_template();
}

{
    my $DATA;
    sub process_template {
        $DATA ||= join "" => <DATA>;
        Template->new->process(
            \$DATA,
            {
                'get_all_metaclasses'   => \&::get_all_metaclasses,
                'get_metaclass_by_name' => \&::get_metaclass_by_name,
                'deparse_method'        => \&::deparse_method,
                'deparse_item'          => \&::deparse_item,
            }
        ) or warn Template->error;
    }
}

sub get_all_metaclasses {
    sort { $a->name cmp $b->name } Class::MOP::get_all_metaclass_instances()
}

sub get_metaclass_by_name {
    Class::MOP::get_metaclass_by_name(@_);
}

sub deparse_method {
    my ($method) = @_;
    my $deparse = B::Deparse->new("-d");
    my $body = $deparse->coderef2text($method->body());
    return "sub " . $method->name . ' ' . _clean_deparse_code($body);
}

sub deparse_item {
    my ($item) = @_;
    return $item unless ref $item;
    local $Data::Dumper::Deparse = 1;
    local $Data::Dumper::Indent  = 1;
    my $dumped = Dumper $item;
    $dumped =~ s/^\$VAR1\s=\s//;
    $dumped =~ s/\;$//;
    return _clean_deparse_code($dumped);
}

sub _clean_deparse_code {
    my @body = split /\n/ => $_[0];
    my @cleaned;
    foreach (@body) {
        next if /^\s+use/;
        next if /^\s+BEGIN/;
        next if /^\s+package/;
        push @cleaned => $_;
    }
    return (join "\n" => @cleaned);
}

1;

## This is the template file to be used

__DATA__
[% USE q = CGI %]

[% area = 'attributes' %]
[% IF q.param('area') %]
    [% area = q.param('area') %]
[% END %]

<html>
<head>
<title>Class::MOP Browser</title>
<style type='text/css'>

body {
    font-family: arial;
}

td { font-size: 12px; }
b  { font-size: 12px; }

pre {
    font-family: courier;
    font-size:   12px;
    width:       330px;
    padding:     10px;
    overflow:    auto;
    border:      1px dotted green;
}

A {
    font-family: arial;
    font-size:   12px;
    color: black;
    text-decoration: none;
}

A:hover {
    text-decoration: underline;
}

td.lightblue  {
    background-color: #99BBFF;
    border-right:  1px solid #336699;
    border-bottom: 1px solid #336699;
    border-top:    1px solid #BBDDFF;
    border-left:   1px solid #BBDDFF;
}

td.grey       {
    background-color: #CCCCCC;
    border-right:  1px solid #888888;
    border-bottom: 1px solid #888888;
    border-top:    1px solid #DDDDDD;
    border-left:   1px solid #DDDDDD;
}

td.manila     {
    background-color: #FFDD99;
    border-right:  2px solid #CC9933;
    border-bottom: 2px solid #CC9933;
    border-top:    2px solid #FFFFBB;
    border-left:   2px solid #FFFFBB;
}

td.darkgreen  {
    background-color: #33CC33;
    border-right:  1px solid #009900;
    border-bottom: 1px solid #009900;
    color: #CCFFCC;
}

td.lightgreen {
    background-color: #AAFFAA;
    border-right:  1px solid #33FF33;
    border-bottom: 1px solid #33FF33;
}

</style>
</head>
<body>
<h1>Class::MOP Browser</h1>
<table bgcolor='#CCCCCC' cellpadding='0' cellspacing='0' border='0' align='center' height='400'>
<tr valign='top'>

<td rowspan='2' width='200'><table cellspacing='0' cellpadding='5' border='0' width='100%'>
    [% FOREACH metaclass IN get_all_metaclasses() %]
        <tr>
        [% IF q.param('class') == metaclass.name %]
            <td class='lightblue'><b>[% metaclass.name %]</b></td>
        [% ELSE %]
            <td class='grey'><a href='?class=[% metaclass.name %]'>[% metaclass.name %]</a></td>
        [% END %]
        </tr>
    [% END %]
    </table></td>
<td height='10' width='250'><table cellspacing='0' cellpadding='5' border='0' width='100%'>
    <tr align='center'>
    [% FOREACH area_name IN [ 'attributes', 'methods', 'superclasses' ] %]
        [% IF q.param('class') %]
            [% IF area == area_name %]
                <td class='manila'><b>[% area_name %]</b></td>
            [% ELSE %]
                <td class='lightblue'><a href='?class=[% q.param('class') %]&area=[% area_name %]'>[% area_name %]</a></td>
            [% END %]
        [% ELSE %]
            <td class='lightblue' style="color: #336699;">[% area_name %]</td>
        [% END %]
    [% END %]
    </tr>
    </table></td>

<td valign='top' rowspan='2' class='lightgreen' width='450'>
    <table cellspacing='0' cellpadding='3' border='0'>
    <tr>
    <td class='darkgreen' width='100'></td>
    <td class='darkgreen' width='350'></td>
    </tr>
    [% IF q.param('class') && area == 'attributes' && q.param('attr') %]

    [%
        meta = get_metaclass_by_name(q.param('class'))
        attr = meta.get_attribute(q.param('attr'))
    %]

        [% FOREACH aspect IN [ 'name', 'init_arg', 'reader', 'writer', 'accessor', 'predicate', 'default' ]%]
            [% item = attr.$aspect() %]
            <tr>
            <td class='darkgreen' align='right' valign='top'>[% aspect %]</td>
            <td class='lightgreen'>[% IF item == undef %]&mdash;[% ELSE %]<pre>[% deparse_item(item) %]</pre>[% END %]</td>
            </tr>
        [% END %]

    [% ELSIF q.param('class') && area == 'methods' && q.param('method') %]

    [%
        meta = get_metaclass_by_name(q.param('class'))
        method = meta.get_method(q.param('method'))
    %]

        [% FOREACH aspect IN [ 'name', 'package_name', 'fully_qualified_name' ]%]
            <tr>
            <td class='darkgreen' align='right' valign='top'>[% aspect %]</td>
            <td class='lightgreen'>[% method.$aspect() %]</td>
            </tr>
        [% END %]
            <tr>
            <td class='darkgreen' align='right' valign='top'>body</td>
            <td class='lightgreen'><pre>[% deparse_method(method) %]</pre></td>
            </tr>

    [% END %]
    </table></td>

</tr>
<tr>

[% IF q.param('class') && area %]

[% meta = get_metaclass_by_name(q.param('class')) %]

<td class='lightblue' valign='top'><div style='height: 100%; overflow: auto;'><table cellspacing='0' cellpadding='5' border='0' width='100%'>

    [% IF area == 'methods' %]
        [% FOREACH method IN meta.get_method_list.sort %]
            <tr>
                [% IF q.param('method') == method %]
                    <td class='darkgreen'><b>[% method %]</b></td>
                [% ELSE %]
                    <td class='manila'><a href='?class=[% q.param('class') %]&area=[% q.param('area') %]&method=[% method %]'>[% method %]</a></td>
                [% END %]
            </tr>
        [% END %]
    [% END %]
    [% IF area == 'attributes' %]
        [% FOREACH attr IN meta.get_attribute_list.sort %]
            <tr>
                [% IF q.param('attr') == attr %]
                    <td class='darkgreen'><b>[% attr %]</b></td>
                [% ELSE %]
                    <td class='manila'><a href='?class=[% q.param('class') %]&area=[% q.param('area') %]&attr=[% attr %]'>[% attr %]</a></td>
                [% END %]
            </tr>
        [% END %]
    [% END %]
    [% IF area == 'superclasses' %]
        [% FOREACH super IN meta.superclasses.sort %]
            <tr>
                <td class='manila'><a href='?class=[% super %]'>[% super %]</a></td>
            </tr>
        [% END %]
    [% END %]
    </table></div></td>
[% END %]

</tr>
</table>
</body>
</html>

