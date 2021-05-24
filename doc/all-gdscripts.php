<?php
$outputFile = __DIR__ . '/all-gdscripts.md';

chdir(__DIR__ . '/..');

$output = "# GDScripts\n\n";

$dirIterator = new RecursiveDirectoryIterator('.');
$filterExtensions = ['gd'];
foreach (new RecursiveIteratorIterator($dirIterator) as $file) {
	$parts = explode('.', $file);
	$ext = strtolower(array_pop($parts));
	if (!in_array($ext, $filterExtensions))
		continue;
	$file = substr($file, 2);
	echo($file . "\n");

	$output .= "## `$file`\n```\n";
	$output .= file_get_contents($file);
	$output .= "```\n\n";
}

file_put_contents($outputFile, $output);
