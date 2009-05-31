<?xml version="1.0" encoding="UTF-8" ?>

<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/"
                xmlns:aws="http://webservices.amazon.com/AWSECommerceService/2005-02-23">


  <xsl:output method="xml"/>
  <xsl:variable name="count" select="10" />

  <xsl:variable name="itempage">
    <xsl:choose>
      <xsl:when test="aws:ItemSearchResponse/aws:Items/aws:Request/aws:ItemSearchRequest/aws:ItemPage">
        <xsl:value-of select="aws:ItemSearchResponse/aws:Items/aws:Request/aws:ItemSearchRequest/aws:ItemPage"/>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="pagebase" select="$itempage - 1"/>
  <xsl:variable name="base" select="$count*$pagebase"/>
  <xsl:variable name="associate_id" select="&quot;untonet-20&quot;"/>
  
  <xsl:template match="/">

    <rss version="2.0" xmlns:openSearch="http://a9.com/-/spec/opensearchrss/1.0/">
      <channel>
      <xsl:apply-templates select="aws:ItemSearchResponse/aws:Items/aws:Request/aws:ItemSearchRequest" />
      <xsl:apply-templates select="aws:ItemSearchResponse/aws:Items/aws:TotalResults" />
      <openSearch:startIndex><xsl:value-of select="$base + 1" /></openSearch:startIndex>
      <openSearch:itemsPerPage><xsl:value-of select="$count" /></openSearch:itemsPerPage>
      <xsl:for-each select="aws:ItemSearchResponse/aws:Items/aws:Item">
         <xsl:call-template name="item-node" /> 
      </xsl:for-each>

      </channel>

    </rss>
  </xsl:template>


<xsl:template match="aws:ItemSearchRequest">
  <title>Search for <xsl:value-of select="aws:SearchIndex" /> via unto.net: <xsl:value-of select="aws:Keywords" /> </title>
  <link>http://www.unto.net/aws?searchTerms=<xsl:value-of select="translate(aws:Keywords,' ','+')" />&amp;searchIndex=<xsl:value-of select="aws:SearchIndex" />&amp;format=html</link>
  <description>Search for <xsl:value-of select="aws:SearchIndex" /> via unto.net: <xsl:value-of select="aws:Keywords" /> </description>
  <language>en-us</language>
</xsl:template>


<xsl:template match="aws:TotalResults">
  <openSearch:totalResults><xsl:value-of select="." /></openSearch:totalResults>
</xsl:template>


<xsl:template name="item-node">
  <item>
    <title><xsl:value-of select="aws:ItemAttributes/aws:Title" /></title>
    <link>http://www.amazon.com/exec/obidos/ASIN/<xsl:value-of select="aws:ASIN" />/ref=nosim/<xsl:value-of select="$associate_id" /></link> 
    <guid isPermaLink="true">http://www.amazon.com/exec/obidos/ASIN/<xsl:value-of select="aws:ASIN" />/ref=nosim/<xsl:value-of select="$associate_id" /></guid> 
<!--    <link><xsl:value-of select="aws:DetailPageURL" /></link> -->
    <description>
      &lt;span&gt;


      <xsl:if test="aws:SmallImage/aws:URL">

        &lt;a href="http://www.amazon.com/exec/obidos/ASIN/<xsl:value-of select="aws:ASIN" />/ref=nosim/<xsl:value-of select="$associate_id" />" &gt;
        &lt;img src="<xsl:value-of select="aws:SmallImage/aws:URL" />"
                border="0"
                align="top"
                style="float: left; padding: 5px;"
                height="<xsl:value-of select="aws:SmallImage/aws:Height" />"
                width="<xsl:value-of select="aws:SmallImage/aws:Width" />" /&gt;&lt;/a&gt;
        

      </xsl:if>

      <xsl:if test="aws:ItemAttributes/aws:Author">
        <xsl:text> by </xsl:text>
       <xsl:for-each select="aws:ItemAttributes/aws:Author">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>. </xsl:text>
      </xsl:if>
      <xsl:if test="aws:ItemAttributes/aws:Artist">
        <xsl:text> by </xsl:text>
        <xsl:value-of select="aws:ItemAttributes/aws:Artist" />
        <xsl:text>. </xsl:text>
      </xsl:if>
      <xsl:if test="aws:ItemAttributes/aws:Manufacturer">
        <xsl:text> from </xsl:text>
        <xsl:value-of select="aws:ItemAttributes/aws:Manufacturer" />
        <xsl:text>. </xsl:text>
      </xsl:if>
      <xsl:if test="aws:ItemAttributes/aws:Label">
        <xsl:value-of select="aws:ItemAttributes/aws:Label" />
        <xsl:text>. </xsl:text>
      </xsl:if>
      <xsl:if test="aws:ItemAttributes/aws:Format">
        <xsl:text> Format: </xsl:text>
       <xsl:for-each select="aws:ItemAttributes/aws:Format">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>. </xsl:text>
      </xsl:if>


      <xsl:if test="aws:ItemAttributes/aws:ListPrice/aws:FormattedPrice">
        <xsl:text> List: </xsl:text>
        &lt;s&gt;
        <xsl:value-of select="aws:ItemAttributes/aws:ListPrice/aws:FormattedPrice" />
        &lt;/s&gt;
        <xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:if test="aws:OfferSummary/aws:LowestNewPrice/aws:FormattedPrice">
        <xsl:text> New: </xsl:text>
        <xsl:value-of select="aws:OfferSummary/aws:LowestNewPrice/aws:FormattedPrice" />
        <xsl:text>.</xsl:text>
      </xsl:if>

<!--    <xsl:if test="aws:OfferSummary/aws:LowestUsedPrice/aws:FormattedPrice">
        <xsl:text> Used: </xsl:text>
        <xsl:value-of select="aws:OfferSummary/aws:LowestUsedPrice/aws:FormattedPrice" />
        <xsl:text>.</xsl:text>
      </xsl:if> -->
      &lt;/span&gt;


      <xsl:if test="aws:EditorialReviews/aws:EditorialReview/aws:Content">
        &lt;p&gt;<xsl:value-of select="aws:EditorialReviews/aws:EditorialReview/aws:Content" />&lt;/p&gt;
      </xsl:if>


    </description>
  </item>
  <xsl:text>

  </xsl:text>
</xsl:template>

</xsl:stylesheet> 
