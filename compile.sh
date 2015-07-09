#!/bin/bash
set -e

pkgs="--pkg gtk+-3.0 --pkg gee-0.8 --pkg json-glib-1.0"

lib ()
{
	contiune=false
	for f in ../src/libsplat/*; do
		if [ $f -nt libsplat.so ]; then
			contiune=true
			break;
		fi
	done

	if $contiune; then
		echo "Compiling lib"
		valac $pkgs --library=libsplat -H libsplat.h -g -o libsplat.so ../src/libsplat/* -X -fPIC -X -shared
	fi
}

core ()
{
	contiune=false
	for f in ../src/core/*; do
		if [ $f -nt splat ]; then
			contiune=true
			break;
		fi
	done

	if $contiune; then
		echo "Compiling core"
		valac --vapidir . $pkgs --pkg libsplat -g -o splat ../src/core/* -X -ldl -X -I. -X -L. -X -lsplat -X -Wl,-rpath=$(pwd) -X -rdynamic 
	fi
}

plugins ()
{
	echo "Compiling plugins"
	for d in ../src/plugins/*/ ; do
		name=$(basename $d)

		contiune=false
		for f in $d*; do
			if [ $f -nt plugins/$name.so ]; then
				contiune=true
				break;
			fi
		done

		if $contiune; then
			echo "	$name"
			echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<gresources>
	  <gresource prefix=\"/\">
	    <file compressed=\"true\">meta.json</file>
	  </gresource>
	</gresources>" > temp/$name.gresource.xml
			glib-compile-resources --generate-source --sourcedir $d temp/$name.gresource.xml
			[ -f $d/options ] && options=`cat $d/options`
			valac $options --vapidir . $pkgs --pkg libsplat --gresources=temp/$name.gresource.xml -o plugins/$name.so -H $name.h --library=$name $d*.vala temp/$name.c -X -fPIC -X -shared -X -I. -X -L. -g
		fi
	done
}

res ()
{
	echo "Copying resources."
	for f in ../res/* ; do
		if [ $f -nt ./$(basename $f) ]; then
			echo "$f => target/$(basename $f)"
			cp -r $f ./
		fi
	done
}

if [ "$1" = "run" ]; then
	cd target
	./splat
elif [ "$1" = "clean" ]; then
	rm -r target
elif [ "$1" = "debug" ]; then
	cd target
	gdb splat
else
	mkdir -p target/plugins
	mkdir -p target/temp
	cd target
	res
	lib
	core
	plugins
	rm -r temp
fi
