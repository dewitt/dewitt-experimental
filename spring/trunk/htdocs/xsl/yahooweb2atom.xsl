<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"
                xmlns:yahoo="urn:yahoo:srch"
                exclude-result-prefixes="yahoo">

  <xsl:output method="xml"/>

  <xsl:param name="searchTerms">cat</xsl:param>
  <xsl:param name="itemsPerPage">10</xsl:param>

  <xsl:template match="/">
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/">
      <title type="text">Yahoo search for "<xsl:value-of select="translate( $searchTerms, '+', ' ' )" />" via Unto.net</title>
      <Query role="request"> 
        <xsl:param name="startIndex" select="yahoo:ResultSet/@firstResultPosition"/>
        <xsl:attribute name="startPage"><xsl:value-of select="floor( $startIndex div $itemsPerPage ) + 1"/></xsl:attribute> 
        <xsl:attribute name="searchTerms"><xsl:value-of select="$searchTerms"/></xsl:attribute>
      </Query>
      <opensearch:link rel="search"
         href="/spring/search/yahoo?format=description" type="application/opensearchdescription+xml"/>
      <opensearch:itemsPerPage><xsl:value-of select='$itemsPerPage'/></opensearch:itemsPerPage>
      <opensearch:totalResults><xsl:value-of select="yahoo:ResultSet/@totalResultsAvailable" /></opensearch:totalResults>
      <opensearch:startIndex><xsl:value-of select="yahoo:ResultSet/@firstResultPosition" /></opensearch:startIndex>
      <xsl:for-each select="yahoo:ResultSet/yahoo:Result">
      <entry>
        <title><xsl:value-of select="yahoo:Title"/></title>
        <link><xsl:value-of select="yahoo:Url"/></link>
        <id><xsl:value-of select="yahoo:Url"/></id>
        <summary type="html"><xsl:value-of select="yahoo:Summary"/></summary>
      </entry>
      </xsl:for-each>
    </feed>
  </xsl:template>
</xsl:stylesheet>

