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

##Imports
All imports are from the same directory

###proclitic\_inc.xsl, enclitic\_inc.xsl
Merge proclitics and enclitics with head words. These files import **proclitics.xml** and **enclitics.xml**, respectively.

###lexical_inc.xsl
Manages lexical exceptions to the orthography-to-phonetics algorithm. Imports **lexical.xml**.

<!-- Not used; will be needed for approximate matching
###bitmask.xsl
Imported by **rhyme.xsl**. The `rhymeComp()` function returns a sequence of three items: 1) a bit string representing their XOR value (1 = location of difference); 2) a list of bit positions that are similar, string-joined across a hyphen; and 3) the proportion of correspondence as a double between 0 and 1.
-->

##Diagnostic
###rhyme-test_2016-05-11.xsl
Run **rhyme-test_2016-05-11.xsl** against itself to output lines with rhyme attributes and diagnostic information. Input is transliterated.
###rhyme-test_2016-05-14.xsl
Run **rhyme-test_2016-05-14.xsl** against itself to process Cyrillic input.
###phoneticize-test_2016-05-14.xsl
Run **phoneticize-test_2016-05-14.xsl** against itself to output phonetic representation of rhyme string.
###lexical_test.xsl
Run **lexical_test.xsl** against itself to make lexical-level adjustments in test words (included in the XSLT file).

##Documentary
###feature-chart.xhtml
**feature-chart.xhtml** offers a matrix of phonetic features according to our transcription system. The segments constitute the rows and the features are 0 and 1, so that the file can be used to extract a bit string for bitwise comparisons.

###flipTable.xsl
**flipTable.xsl** swaps the rows and columns of a table. Useful when the developer makes the wrong decision initially.


