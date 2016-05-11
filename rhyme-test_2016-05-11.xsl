<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <!--
        Filename: rhyme-test_2016-05-11.xsl
        Developer: djb 2015-05-11
        Repo: http://github.com/djbpitt/poetry
        Synopsis: Run against itself to identify rhyme scheme in included $poem variable
        License: GNU AGPLv3
    -->
    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="input" as="element(poem)">
        <!-- 
      $poem = sample input in phonetic transcription
      <poem> root has <line> children, which are mixed content with <stress> elements
      Upper-case = palatalized
      y and i are both rendered as i
      Punctuation except hyphens stripped, orthographic spacing retained
    -->
        <poem>
            <line>moj D<stress>a</stress>Di s<stress>a</stress>mix č<stress>e</stress>stnix
                    pr<stress>a</stress>Vil</line>
            <line>kagd<stress>a</stress> Ni f š<stress>u</stress>tku zaNim<stress>o</stress>k</line>
            <line>on uvaž<stress>a</stress>T SiB<stress>a</stress> zast<stress>a</stress>Vil</line>
            <line>i l<stress>u</stress>čši v<stress>i</stress>dumaT Ni m<stress>o</stress>k</line>
            <line>jiv<stress>o</stress> pRidM<stress>e</stress>t druG<stress>i</stress>m
                    na<stress>u</stress>ka</line>
            <line>no b<stress>o</stress>ži m<stress>o</stress>j kak<stress>a</stress>ja
                    sk<stress>u</stress>ka</line>
            <line>z baLn<stress>i</stress>m SiD<stress>e</stress>T i D<stress>e</stress>N i
                    n<stress>o</stress>č</line>
            <line>Ni atxaD<stress>a</stress> Ni š<stress>A</stress>gu pr<stress>o</stress>č</line>
            <line>kak<stress>o</stress>ji N<stress>I</stress>skaji kav<stress>a</stress>rstva</line>
            <line>palu-živ<stress>o</stress>va zabavL<stress>a</stress>T</line>
            <line>jim<stress>u</stress> pad<stress>u</stress>šKi papravL<stress>a</stress>T</line>
            <line>Pič<stress>a</stress>Lna padnaS<stress>i</stress>T
                Lik<stress>a</stress>rstva</line>
            <line>vzdix<stress>a</stress>T i d<stress>u</stress>maT pra SiB<stress>a</stress></line>
            <line>kagd<stress>a</stress> ži č<stress>o</stress>rt vaZM<stress>o</stress>t
                    TiB<stress>a</stress></line>
        </poem>
    </xsl:variable>
    <!--
    Other stylesheet variables:
    $alphabet = used to indicate rhyme; will fail if there are more than 26 rhyming groups
    $vowels = used to count rhyming and post-rhyme vowels to distinguish masculine vs feminine rhyme
  -->
    <xsl:variable name="alphabet"
        select="tokenize('a b c d e f g h i j k l m n o p q r s t u v w x y z', ' ')"
        as="xs:string+"/>
    <xsl:variable name="vowels" select="tokenize(('a e i o u'), ' ')" as="xs:string+"/>
    <xsl:template match="/">
        <xsl:variable name="outputLines" as="element(line)+">
            <!--
      $outputLines = lines are grouped and sorted by rhyme, and therefore out of original order, 
        but with original order retained as @position attribute, so that $outputLines can be restored
            to original order before final output
        spaces are stripped from grouping key (using translate()) so that sounds will match irrespective 
            of whitespace characters
    -->
            <xsl:for-each-group select="$input//line"
                group-by="translate(string-join((stress[last()], text()[not(following-sibling::stress)]), ''), ' ', '')">
                <!-- All lines in poem; process instead by stanza for poems with multiple stanzas (will break on terza rima) -->
                <!-- 
          Template variables:
          $offset = order of rhyme group in sequence of all rhyme groups, used to choose representative letter
          $letter = letter to represent rhyme group
          $rhymeString = concatenation of final stressed vowel plus all following text() nodes, with spaces stripped
            To do: supporting consonant for open masculine rhyme
          $gender = capitalizes rhyme letter for feminine, lowercase for masculine
            To do: add dactylic and hyperdactylic
        -->
                <xsl:variable name="offset" select="position()" as="xs:integer"/>
                <xsl:variable name="letter" select="$alphabet[$offset]" as="xs:string"/>
                <xsl:variable name="rhymeString" select="current-grouping-key()" as="xs:string"/>
                <xsl:variable name="gender"
                    select="
                        if (count(for $char in string-to-codepoints(current-grouping-key())
                        return
                            codepoints-to-string($char)[. = $vowels]) eq 1) then
                            'masc'
                        else
                            'fem'"
                    as="xs:string"/>
                <xsl:for-each select="current-group()">
                    <!--
            Attributes on <line> elements in output:
            @rhymeString = concatenation of final stressed vowel plus all following text() nodes, with spaces stripped
              copied from $rhymeString, which is equal to current-grouping-key()
            @rhyme = uppercase (feminine) or lowercase (masculine) letter, in order of appearance of rhyme group in poem
            @position = original position of line in poem (to restore original sort order later)
          -->
                    <line rhymeString="{$rhymeString}"
                        rhyme="{if ($gender eq 'masc') then $letter else upper-case($letter)}"
                        position="{count(preceding-sibling::line) + 1}">
                        <xsl:sequence select="./node()"/>
                    </line>
                </xsl:for-each>
            </xsl:for-each-group>
        </xsl:variable>
        <poem>
            <xsl:for-each select="$outputLines">
                <!--
          $outputLines is sorted by rhyme group; this restores original poem order
        -->
                <xsl:sort select="number(@position)"/>
                <xsl:sequence select="."/>
            </xsl:for-each>
        </poem>
    </xsl:template>
</xsl:stylesheet>
