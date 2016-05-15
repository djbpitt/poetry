#poetry
Machine-assisted analysis of Russian verse

Part of <http://poetry.obdurodon.org>.

Master branch should be stable. Dev branch may be further advanced.

##Production
###rhyme.xsl
Run **rhyme.xsl** against XML input document or against itself. Input must be structured as:

```
<poem>
	<meta>
	<!-- whatever you want-->
	</meta>
	<body>
		<stanza>
			<line> ... </line>
			<!-- more lines -->
		</stanza>
		<!-- more stanzas -->
	</body>
</poem>
```
	
Note that `<stanza>` is required. `<line>` elements contain a combination of `text()` nodes and `<stress>` elements.

Imports **proclitic_inc.xsl** and **enclitic_inc.xsl** from the same directory.

##Auxiliary supporting files
* **proclitic_inc.xsl** and **enclitic_inc.xsl** are imported (from the same directory) by others to merge proclitics and enclitics with head words. Import **proclitics.xml** and **enclitics.xml**, respectively, also from the same directory.

##Diagnostic
###rhyme-test_2016-05-11.xsl
Run rhyme-test_2016-05-11.xsl against itself to output lines with rhyme attributes and diagnostic information. Input is transliterated.
###rhyme-test_2016-05-14.xsl
Run rhyme-test_2016-05-14.xsl against itself to process Cyrillic input.
###phoneticize-test_2016-05-14.xsl
Run phoneticize-test_2016-05-14.xsl against itself to output phonetic representation of rhyme string.


