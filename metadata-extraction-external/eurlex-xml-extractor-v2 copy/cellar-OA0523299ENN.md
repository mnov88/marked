Cellar

**The semantic repository of the Publications Office**

##### 2023 EDITION

Manuscript completed in August 2023.

More information on the European Union is available on the internet ([http://europa.eu](http://europa.eu/)). Luxembourg: Publications Office of the European Union, 2023

| Print | ISBN 978-92-78-43687-2 | doi:10.2830/918999 | OA-05-23-299-EN-C |
|-------|------------------------|--------------------|-------------------|
| PDF   | ISBN 978-92-78-43686-5 | doi:10.2830/654692 | OA-05-23-299-EN-N |

© European Union, 2023

Reuse is authorised provided the source is acknowledged.

Cellar

**The semantic repository of the Publications Office**

## Contents

1.  [Introduction 5](#introduction)
    1.  [Objective and target audience 5](#introduction)
    2.  [Structure of the document 5](#introduction)
    3.  [Contact us 5](#introduction)
    4.  [Update of this document 6](#update-of-this-document)
    5.  [Service level agreement 6](#update-of-this-document)

        [PART I: Semantic access and use cases 7](#part-i)

2.  [Semantic web technologies 8](#semantic-web-technologies)
    1.  [Naming things with URIs 9](#naming-things-with-uris)
    2.  [Dereferencing URIs 10](#dereferencing-uris)
    3.  [Semantic modelling 11](#_bookmark8)
    4.  [From SQL to SPARQL 14](#from-sql-to-sparql)
3.  [Access possibilities 15](#access-possibilities)
    1.  [EUR-Lex RSS 16](#eur-lex-rss)
    2.  [Cellar RSS 17](#cellar-rss)
    3.  [EUR-Lex web services 17](#cellar-rss)
    4.  [Cellar SPARQL endpoint 17](#cellar-rss)
    5.  [Cellar RESTful interface 18](#_bookmark19)
4.  [Use cases 19](#use-cases)
    1.  [Subject-related searches: a use case with Eurovoc 19](#use-cases)

        [4 2. Getting metadata related to Official Journals (OJs) 22](#getting-metadata-related-to-official-journals-ojs)

    2.  [Download a part or the whole of the repository 24](#download-a-part-or-the-whole-of-the-repository)
    3.  [Old license holder extractions at the OP 24](#download-a-part-or-the-whole-of-the-repository)
    4.  [Case-law 26](#case-law)
    5.  [EU treaties 27](#eu-treaties)
    6.  [EU legislation in force about climate change 27](#eu-treaties)

        [PART II: Technical reference 28](#part-ii)

5.  [RESTful and RSS API 29](#restful-and-rss-api)
    1.  [Main concepts 29](#restful-and-rss-api)

[5.1 1. Functional requirements for bibliographic records (frbr) 29](#restful-and-rss-api)

1.  [Types of notices 32](#types-of-notices)
    1.  [Content streams 33](#identifier-notice)
        1.  [NALs 33](#identifier-notice)
        2.  [Eurovoc 34](#eurovoc)
        3.  [Resource URI 34](#eurovoc)
    2.  [Available services 37](#_bookmark42)
        1.  [WEMI services 38](#_bookmark43)
        2.  [NAL/Eurovoc services 56](#_bookmark44)
        3.  [Notifications: RSS and Atom feeds 67](#_bookmark45)
2.  [Master data 72](#master-data)
    1.  [Ontology: CDM 72](#master-data)
    2.  [Authority tables, Eurovoc 73](#_bookmark48)
    3.  [Instance data: OJ example 74](#instance-data-oj-example)
    4.  [Formex 74](#instance-data-oj-example)

[PART III: Annexes 75](#part-iii-annexes)

## ![](8334caa65ce9174619382b9cbd882e42.png)Introduction

#### Introduction

Following the decision on reuse (1), the Publications Office (OP) put in place the Cellar, a repository to incorporate its publications. Currently, EUR-Lex (2), the EU- Bookshop (3) and others are included in the Cellar.

The Cellar is based on semantic technologies: a framework of several standards to share and reuse data. They normalise named resources in controlled vocabularies, which allows computers to talk and link to one another.

### Objective and target audience

This document provides information and examples on how to access content files and metadata from the Cellar, the digital dissemination repository of the OP.

Though it is open to all citizens, this document is aimed mainly at reusers and companies who want to automatise their access to OP publications. If you are interested in regular, but not automatised access, you may find better, more relevant information in their respective portals.

### Structure of the document

This document is structured in three parts.

**Part I:** how to access the Cellar, with real use case examples.

**Part II:** technical references, with all the possibilities of the application programming interface (API), ontol´ogies and authority tables.

**Part III:** appendixes, with a glossary and references.

### Contact us

The OP is responsible for the operational management and improvement of the Cellar. Please send us an email at [OP-SD2C@ec.europa.eu](mailto:OP-SD2C@ec.europa.eu) if you are aware of any of the following items, or for any other problem or enhancement you would like to communicate to us:

-   an error in the data or the metadata;
-   a useful use-case that might be of interest;
-   a SPARQL query that does not work;
-   an error in the Cellar interfaces or in its content;
-   an error in this document.
1.  European Commission, ‘Commission decision on the reuse of Commission documents’, Official Journal of the European Union (OJ L 330, 14.12.2011, pp. 39-42). Retrieved from [http://eur-lex.europa.eu/legal-content/en/TXT/?uri=CELEX:32011D0833](http://eur-lex.europa.eu/legal-content/en/TXT/?uri=CELEX%3A32011D0833) on 03/10/2016.
2.  <http://eur-lex.europa.eu/>
3.  <http://bookshop.europa.eu/>

![](a742586b1a6331a3e480e49c75e53171.png)

### Update of this document

This document will be updated as often as needed or possible, always on a best- effort basis, usually when errors are spotted and corrected, or when a new Cellar version is deployed or any of its interfaces change.

### Service level agreement

Access to the Cellar API is given on a best-effort basis. No level of service performance can be guaranteed at this stage.

If you are planning to try to access the Cellar interfaces repeatedly, there is a chance you might get an access error after a few hits. This is set up on the EU firewalls: there is no designed limitation on the Cellar. Please remember that resources are (always) limited, be respectful of that limited availability and do not try to download the whole Cellar (this is explained further in section 4.3).

The SPARQL endpoint in particular might show some stability issues due to its nature as state-of-the-art technology, i.e. it may suffer from lack of maturity (4). We know this and we reassure you: we are continuing to work on it and hope and thank you for your patience.

1.  A list of other SPARQL endpoints is given by W3c at <https://www.w3.org/wiki/SparqlEndpoints>.

# PART I:

**Semantic access and use cases**

![](a742586b1a6331a3e480e49c75e53171.png)

## Semantic web technologies

The semantic web is an evolution of the World Wide Web that allows for automating tasks on the web, letting computers talk to each other. In order to do so, data must follow common formats, structures and standards known by all participating systems. That group of standards is called the semantic web and a few are shown in Figure 1.

**Figure 1: Semantic web technologies stack**

![](56881180ab4c17106cab9fdd26a0b408.png)![](73fe66b4d07a777147f24075913dd4f2.png)![](b0753e1c9052529a585382365da434c5.png)

*Source:* Wikipedia (Semantic web stack.svg, user Marobi1;

*https://en.wikipedia.org/wiki/Semantic_Web_Stack\#/media/File:Semantic_web_stack.svg*)

Some semantic concepts are explained in the following sections. More detailed information on the semantic web can be found on the World Wide Web Consortium (W3C) website (5).

1.  <https://www.w3.org/2013/data/>

![](8334caa65ce9174619382b9cbd882e42.png)

### Naming things with URIs

The first thing needed to understand the semantic web is the standard in naming things with common vocabularies and names (identifiers). In order to get universal identifiers that were common to all world computers, a very simple approach was taken: using the existing web. These identifiers are called uniform resource identifiers (URIs) and look very much like web addresses or uniform resource locators (URLs), though they are not the same. A URI can have a web page or URL, but its main use is as a universal identifier. For example,

-   \<<http://publications.europa.eu/resource/oj/JOA_1952_001_R>\> is both a URI and a valid URL, because when typed in a web browser, it returns some content or metadata associated with it. Here, we say that the URI is ‘dereferenceable’.
-   \<[http://publications.europa.eu/ontology/cdm\#act_body\_](http://publications.europa.eu/ontology/cdm#act_body_) agreement_international\> is a URI (it identifies a type of document in the ontology) for the moment; it could also become a URL if it is mapped to a web page.

    Other websites in or outside the Cellar can use the same identifiers and even refer to them. In the rest of the document, the term URI will be used, and it may or may not point to a website.

    The important part here is that URIs *do not change*.

*‘What makes a cool URI?*

*A cool URI is one which does not change.*

*What sorts of URI change?*

*URIs don’t change: people change them.’*

**Tim Berners-Lee, 1998**

[*https://www.w3.org/Provider/Style/URI*](https://www.w3.org/Provider/Style/URI)

URIs in the Cellar will not change.

The OP will ensure this with data modelling and a number of technologies so you don’t need to worry, or to search every time, or to download anything to compare or map to previous identifiers.

More information on best practices on naming things in the semantic web can be found in the excellent free online book *Linked Data Patterns* by Leigh Dodds and Ian Davis (6).

1.  <http://patterns.dataincubator.org/book/>

![](a742586b1a6331a3e480e49c75e53171.png)

### Dereferencing URIs

Machines and humans do not see information in the same way. When accessing a URI, a computer receives a different version of what people see in the browser.

When the Cellar is asked for a URI, it returns information depending on who is asking.

-   When it is a computer (in general), the Cellar responds with a resource description framework (RDF — see next section) with the description of the URI, with all available metadata at that level.
-   When it is a human, the Cellar responds by default with the content related to the URI — either PDF, or HTML, or any other format available. (This depends on the browser, especially for formats which need plugins, like PDF).

    This is done via a mechanism called content negotiation. You already know and use it: when you browse on the internet, a request for a webpage usually returns it correctly (code ok: 200), or with an error (code 404). This is content negotiation. The Cellar can respond with these or other codes, such as a redirection (code 303), to one of the two modes above, either the RDF or the content.

    Of course, both humans and machines can simulate both ways of obtaining content or metadata. In order to do so, one would need to specify the HTTP headers, with tools like the following.

-   Client URL Request Library (cURL) (7): with the –H option for the headers, and the –L to follow the Cellar redirects. Example:

    curl -L -H “Accept:application/xml;notice=tree” -H “Accept-Language:eng” <http://publications.europa.eu/> resource/oj/C_202151176

-   Modify headers (8) plugin for the Firefox (9) browser: see Figure 2 for a screen capture with a configuration example. A similar plugin (10) exists for the browser Google Chrome (11).
1.  <https://curl.haxx.se/>
2.  <https://addons.mozilla.org/fr/firefox/addon/modify-header-value/>
3.  <http://www.mozilla.org/firefox/>
4.  https://chrome.google.com/webstore/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj?hl=fr[i](https://chrome.google.com/webstore/detail/modheader/idgpnmonknjnojddfkpgkljpfnnfcklj?hl=fri)
5.  <http://www.google.com/chrome/>

![](8334caa65ce9174619382b9cbd882e42.png)

**Figure 2: Screen capture with a configuration example of the modify headers plugin for Mozilla Firefox.**

![The figure shows the modify headers plugin for Mozilla Firefox. The filter of the plugin shows the headers Accept and Accept-Language used by the user. The plug-in allows the priority of headers to be edited, deleted, enabled, disabled or changed. ](69aeff491b59bf777f876d70575515b7.jpeg)

The full specifications for the headers accepted by the Cellar can be found in [chapter 5](#_bookmark34)*.*

### Semantic modelling

Once entities have been named (2.1) and there is a negotiation mechanism to access them (2.2), we can introduce the technologies that can be used to model the relationships. Some definitions follow (12).

**Triple:** a minimal unit of information composed of three parts: subject, predicate or property, and object or value. For example, see Table 1. Triples can also be expressed in RDF format.

**Triplestore:** a database of triples, also known as an RDF triplestore.

**Subject:** any entity upon which we can define properties. The subject is always a URI.

1.  For more formals definitions you may refer to <http://www.w3.org/TR/ld-glossary/>

![](a742586b1a6331a3e480e49c75e53171.png)

**Table 1: Examples of triples (13)**

| **Subject**        | **Property**           | **Object**                                     |
|--------------------|------------------------|------------------------------------------------|
| oj:C_202151176 (²) | cdm:work_date_document | 2021-01-25                                     |
| oj:C_202151176     | rdf:type               | cdm:official-journal-act                       |
| celex:62021CA51176 | cdm:work_part_of_event | case-event:C-77%2F19.CC\_ CD_PUB_OJ_2021-01-25 |
| celex:62021CA51176 | owl:sameAs             | eli:c/2021/51176/oj                            |

**Property:** or predicate, it is a verb explaining how the object is related to the subject. The property is always a URI. Please note that properties can also be subjects in a triple.

**Object:** can be either an entity (expressed with a URI) or a literal value with its data type. Please note that objects with URIs can also be subjects in a triple.

**Ontology:** a formal model that allows knowledge to be represented for a specific domain. An ontology describes the types of things that exist (classes), the relationships between them (properties), and the logical ways those classes and properties can be used together (axioms).

**RDF:** Resource Description Framework. A family of international standards for data interchange on the web. RDF is based on the idea of identifying things using web identifiers or HTTP URIs and describing resources in terms of simple properties and property values. It is the model in which the triples (subject, property, and object) are coded. Some vocabularies are predefined, like RDFS, OWL or SKOS, all used at the OP. An RDF model can be expressed in different serialization formats. Cellar mainly uses the extended markup language (XML). An example of an RDF/XML file is shown in Table 2, with similar contents as the triples in Table 1.

1.  This is an abbreviated form of \<<http://publications.europa.eu/resource/> oj/C_202151176\> as if a prefix was declared. Please note that works like this OJ have several identifiers. The triplestore is normalised to have all properties to the same identifier type, so this result may only be achieved via owl:sameAs property.

![](8334caa65ce9174619382b9cbd882e42.png)

**Table 2: Example of an RDF file with some of the triples from Table 1**

**RDFS:** RDF schema. It provides description of vocabularies to structure RDF resources.

**OWL:** ontology web language. It uses classes, entities and properties to define more complex structures and restrictions, like cardinality, value restrictions or transitive property. The ontology used at the OP is called Common Data Model (CDM) and is further explained in section 6.1.

**SKOS:** simple knowledge organisation system. It provides a framework for defining thesauri, taxonomies and other vocabularies.

**SPARQL:** SPARQL protocol and RDF query language. It is the language used

for querying the RDF triple store via an endpoint. Some examples can be found in Section 4.

**SPARQL endpoint:** access service to a triplestore, receives SPARQL queries and responds with results in a variety of formats, including XML, JSON, HTML, etc.

Further information about semantic technologies can be found in many books and online resources (14).

1.  Popular resources include Heath, T and Bizer, C, ‘Linked Data: Evolving the Web into a Global Data Space (1st edition)’, *Synthesis Lectures on the Semantic Web: Theory and Technology*, Vol. 1, No 1, Morgan & Claypool, 2011, pp. 1-136, (<http://linkeddatabook.com/>). Other books include DuCharme, B, *Learning SPARQL*, O’Reilly, Sebastopol, 2013. In addition, there are numerous online resources.

![](a742586b1a6331a3e480e49c75e53171.png)

### From SQL to SPARQL

In case you already have some knowledge on relational databases, semantic databases are similar. In Table 3 you can find some differences between them.

**Table 3: Differences between relational and semantic databases**

| **Category**          | **Relational database**                                             | **Semantic database**                                        |
|-----------------------|---------------------------------------------------------------------|--------------------------------------------------------------|
| **Storage**           | Several tables with fixed columns, primary keys, foreign keys, etc. | Standard scheme: triple: { subject, property, object/value } |
| **Queries**           | SQL                                                                 | SPARQL                                                       |
| **Performance**       | Very high, mature technology                                        | Variable, new technology                                     |
| **Model**             | Rigid: constraints, keys, triggers, external application            | Flexible: graphs, ontology                                   |
| **Compliance**        | Often vendor-specific, generally not directly portable              | Core SPARQL largely portable                                 |
| **Federation**        | Very difficult or impossible. Syntactic differences                 | Integrated                                                   |
| **Identifiers**       | Own                                                                 | Normalised with URIs                                         |
| **Common use tables** | Must be imported and maintained                                     | Can be linked as authorities                                 |
| **Reasoning**         | External tools                                                      | Integrated in the ontology (e.g. inference)                  |
| **Discovery**         | External tools                                                      | Integrated SPARQL endpoint                                   |
| **Standard**          | ISO                                                                 | W3C recommendation                                           |

![](8334caa65ce9174619382b9cbd882e42.png)![](b2a3c628695abb3ca1eea11f67c886f6.png)

## Access possibilities

**Figure 3: Cellar architecture with detail in interfaces.**

![](8585e4ad85388553f0e373e7ce5e11cc.png)

There are several levels on which access is possible; see Table 4 for a high- level classification:

**Table 4: Access possibilities to Cellar notifications, content and metadata**

| **Access origin**                   | **RSS notifications** | **Metadata**    | **Metadata and content** |
|-------------------------------------|-----------------------|-----------------|--------------------------|
| **EUR-Lex** **(meant for humans)**  | Custom                | Web services    | EUR-Lex website          |
| **Cellar** **(meant for machines)** | Full                  | SPARQL endpoint | RESTful interface        |

![](a742586b1a6331a3e480e49c75e53171.png)

### EUR-Lex RSS

EUR-Lex and the OP Portal are front-ends for the Cellar repository. The EUR-Lex RSS can be useful when one needs a summary of what is being published. It has several categories to choose from.

For the specifications, please refer to the EUR-Lex RSS webpage (<https://eur-lex.europa.eu/content/help/search/predefined-rss.html>).

An example of the content of one of these RSSs is shown in Table 5.

**Table 5: EUR-Lex OJ L Complete Edition RSS extract**

The concrete use of RSS is outside the scope of this document. Information and examples on how to use RSS can be found in Internet.

![](8334caa65ce9174619382b9cbd882e42.png)

### Cellar RSS

The Cellar has its own RSS, which has the same content as EUR-Lex plus other publications (from EU-Bookshop, for example), detailed to the most granular extent possible. Every modification in the metadata for every language, every update of an authority table or ontology, everything will be shown in it.

The Cellar RSS cannot be filtered manually as it is meant to be used by machines. For the full specifications, please refer to the RSS API in section 5.

### EUR-Lex web services

If the RSS is not enough or you have more specific needs (like the documents of a specific sector), we recommend you get web-services notifications.

More information is available on the web services help page

(<https://eur-lex.europa.eu/content/help.html>) and in the manual ([http://eur-lex.](http://eur-lex.europa.eu/content/tools/webservices/SearchWebServiceUserManual_v2.00.pdf) [europa.eu/content/tools/webservices/SearchWebServiceUserManual_v2.00.pdf](http://eur-lex.europa.eu/content/tools/webservices/SearchWebServiceUserManual_v2.00.pdf)).

Please note that the names of fields in EUR-Lex web services may be different from those present in the ontology and the SPARQL endpoint. Therefore, if you implement a service based on EUR-Lex web-services and later want to move to the Cellar, you will need to reimplement or remap field names.

### Cellar SPARQL endpoint

All metadata in the repository can be consulted via the SPARQL endpoint. A complete syntax and semantics specification of SPARQL can be found at the W3C website (15). Queries can be done in the OP’s SPARQL endpoint

(<http://publications.europa.eu/webapi/rdf/sparql>) as shown in Figure 4, though a step-by-step wizard exists as well (<http://publications.europa.eu/en/linked-data>)

as shown in Figure 5. These two solutions are presented in <https://op.europa.eu/en/web/cellar/cellar-data/metadata/knowledge-graph>.

1.  <https://www.w3.org/TR/rdf-sparql-query/>

![](a742586b1a6331a3e480e49c75e53171.png)

**Figure 4: Cellar SPARQL endpoint**

![To query the Cellar SPARQL endpoint, the user fills different fields which are the graph IRI, the Query Text field and some other configurable parameters.](9550f0ed5cd57dec5ebd01bba59d153b.jpeg)

**Figure 5: OP Portal linked data query wizard**

![The interface of the OP Portal linked query wizard allows the user to select scope and metadata, to define some conditions, to customize results and to execute the query by steps.](3895ba5566cfbd21b63b27cfc76d5d62.jpeg)

Several examples can be found in the use cases (see section 4).

### Cellar RESTful interface

All content and metadata can be accessed directly via a RESTful interface, which dereferences the requests upon the headers, as shown in section 2.2.

For the full specifications, please refer to the RESTful API in section 5.

![](8334caa65ce9174619382b9cbd882e42.png)

## Use cases

### Subject-related searches: a use case with Eurovoc

**Scenario:** during a hackathon exercise (Diplohack, Brussels, March 2016), where the objective was to present European citizens with new ways of using EU data to enhance transparency, the following use case was presented as a trigger for further ideas. Imagine someone might want to list the African countries by the number of EU laws related to them.

**Solution:** this can be done with the query in Table 6. Copy all lines from the central column of that table to the input box of the SPARQL endpoint from section 3.4 as shown in Figure 4. Click the ‘Run Query’ button. The results can be seen in Table 7.

**Table 6: Commented SPARQL query to get the list of countries in English, with the EU laws related to them**

| **No** | **SPARQL query line**                                                                                      | **Description**                                                                         |
|--------|------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| **01** | prefix eurovoc: \<[http://eurovoc.europa.eu/schema\#](http://eurovoc.europa.eu/schema)\>                   | Prefixes are used to save space in URIs (see 2.1 and footnote 14) when writing queries  |
| **02** | prefix skos: \<[http://www.w3.org/2004/02/skos/core\#](http://www.w3.org/2004/02/skos/core)\>              |                                                                                         |
| **03** | prefix cdm: \<[http://publications.europa.eu/ontology/cdm\#](http://publications.europa.eu/ontology/cdm)\> |                                                                                         |
| **04** | select \* where {                                                                                          | We select everything that fulfils the following criteria (all must finish with a point) |
| **05** | ?country_code skos:prefLabel ?country_name.                                                                | Link of country code and name                                                           |
| **06** | FILTER(LANGMATCHES(LANG(?country_name), "en")).                                                            | Country name in English                                                                 |
| **07** | ?law cdm:work_is_about_concept_eurovoc?country_code.                                                       | Country name related to a Eurovoc concept                                               |
| **08** | ?country_code skos:inScheme \<[http://eurovoc.europa.](http://eurovoc.europa/) eu/100280\> .               | Eurovoc concept is Africa                                                               |
| **09** | }                                                                                                          |                                                                                         |

**Figure 6: SPARQL endpoint with the query from Table 6 copied and ready to be run**

![The figure presents the Cellar SPARQL endpoint where the query to get the list of countries in English, with the EU laws related to them is copied in the Query Text field.](317ae8089127f1f681e369086cb98101.jpeg)

![](a742586b1a6331a3e480e49c75e53171.png)

**Table 7: Some results of the SPARQL query in Table 6**

| **country_code**                                                   | **country_name** | **law**                                                                                                                                                                                                                                                                                                                                                            |
|--------------------------------------------------------------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/4e4cc353-f06a-11e3-8cd4-01aa75ed71a1) [**resource/cellar/4e4cc353-f06a-11e3-**](http://publications.europa.eu/resource/cellar/4e4cc353-f06a-11e3-8cd4-01aa75ed71a1) [**8cd4-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/4e4cc353-f06a-11e3-8cd4-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/9893362b-76d6-11e3-b889-01aa75ed71a1) [**resource/cellar/9893362b-76d6-11e3-**](http://publications.europa.eu/resource/cellar/9893362b-76d6-11e3-b889-01aa75ed71a1) [**b889-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/9893362b-76d6-11e3-b889-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/2b4d871f-b5b0-11e4-b5b2-01aa75ed71a1) [**resource/cellar/2b4d871f-b5b0-11e4-**](http://publications.europa.eu/resource/cellar/2b4d871f-b5b0-11e4-b5b2-01aa75ed71a1) [**b5b2-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/2b4d871f-b5b0-11e4-b5b2-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/af2d56ea-a962-11e3-86f9-01aa75ed71a1) [**resource/cellar/af2d56ea-a962-11e3-**](http://publications.europa.eu/resource/cellar/af2d56ea-a962-11e3-86f9-01aa75ed71a1) [**86f9-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/af2d56ea-a962-11e3-86f9-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/05ca24b4-52a2-11e3-8945-01aa75ed71a1) [**resource/cellar/05ca24b4-52a2-11e3-**](http://publications.europa.eu/resource/cellar/05ca24b4-52a2-11e3-8945-01aa75ed71a1) [**8945-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/05ca24b4-52a2-11e3-8945-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/0e688f24-11a8-41fd-8e3f-0ac3ee931d2a) [**resource/cellar/0e688f24-11a8-41fd-**](http://publications.europa.eu/resource/cellar/0e688f24-11a8-41fd-8e3f-0ac3ee931d2a) [**8e3f-0ac3ee931d2a**](http://publications.europa.eu/resource/cellar/0e688f24-11a8-41fd-8e3f-0ac3ee931d2a) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/e03ccbc8-0731-4f38-93e5-359a6fc9d5c8) [**resource/cellar/e03ccbc8-0731-4f38-**](http://publications.europa.eu/resource/cellar/e03ccbc8-0731-4f38-93e5-359a6fc9d5c8) [**93e5-359a6fc9d5c8**](http://publications.europa.eu/resource/cellar/e03ccbc8-0731-4f38-93e5-359a6fc9d5c8) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/8761c01c-6f94-11e3-b589-01aa75ed71a1) [**resource/cellar/8761c01c-6f94-11e3-**](http://publications.europa.eu/resource/cellar/8761c01c-6f94-11e3-b589-01aa75ed71a1) [**b589-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/8761c01c-6f94-11e3-b589-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/efbe51bb-6c6a-11e7-b2f2-01aa75ed71a1) [**resource/cellar/efbe51bb-6c6a-11e7-**](http://publications.europa.eu/resource/cellar/efbe51bb-6c6a-11e7-b2f2-01aa75ed71a1) [**b2f2-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/efbe51bb-6c6a-11e7-b2f2-01aa75ed71a1) |
| [**http://eurovoc.europa.eu/1843**](http://eurovoc.europa.eu/1843) | "Mayotte"@en     | [**http://publications.europa.eu/**](http://publications.europa.eu/resource/cellar/240e8198-a71d-11e7-837e-01aa75ed71a1) [**resource/cellar/240e8198-a71d-11e7-**](http://publications.europa.eu/resource/cellar/240e8198-a71d-11e7-837e-01aa75ed71a1) [**837e-01aa75ed71a1**](http://publications.europa.eu/resource/cellar/240e8198-a71d-11e7-837e-01aa75ed71a1) |

A more advanced query could get just the African country names in English, plus the total number of EU laws related to each. The query is shown in Table 8, and after executing it in the SPARQL endpoint, the result is shown in Table 9.

Please note that the order may vary; and also new laws are published every day, so the numbers may increase over time.

**Table 8: Commented SPARQL query to get the list of countries in English, with the EU laws related to them**

![](8334caa65ce9174619382b9cbd882e42.png)

**Table 9: Results of the SPARQL query in Table 8 showing a list of African countries with the number of EU laws related to them**

| **country_name**        | **number of laws** |
|-------------------------|--------------------|
| "Uganda"@en             | 179                |
| "Zimbabwe"@en           | 478                |
| "Guinea"@en             | 257                |
| "Malawi"@en             | 60                 |
| "Madagascar"@en         | 289                |
| "Djibouti"@en           | 39                 |
| "Great Maghreb"@en      | 3                  |
| "Mayotte"@en            | 77                 |
| "Senegal"@en            | 217                |
| "Mauritania"@en         | 317                |
| "Mauritius"@en          | 169                |
| "Sierra Leone"@en       | 99                 |
| "Angola"@en             | 368                |
| "Benin"@en              | 31                 |
| "Niger"@en              | 116                |
| "Horn of Africa"@en     | 123                |
| "sub-Saharan Africa"@en | 133                |
| "Liberia"@en            | 173                |
| **…**                   | …                  |

Finally, with a copy and paste to an external map service (outside the scope of this document), an image like the one shown in Figure 7 can be obtained.

![](98fa914a150c41d49e42d198cf25d3e9.png)![](7dbe5614a657c5ad58e88efc51945c83.png)**Figure 7: Map with the results from Table 9**

![](a742586b1a6331a3e480e49c75e53171.png)

### Getting metadata related to Official Journals (OJs)

##### Getting the table of contents, acts and signature related to the authentic OJ until October 2023

**Scenario:** you want to get all the work URIs (table of contents, acts and signature) related to a specific, authentic Official Journal.

**Solution:** this can be done in SPARQL with the query shown in Table 10. There are as many result rows as acts, shown in Table 11.

**Table 10: SPARQL query for getting the URIs of TOC, acts and signature of an Official Journal**

**Table 11: Results of SPARQL query of Table 10, with the URIs of TOC, acts and signature of the Official Journal** \<<http://publications.europa.eu/> resource/oj/JOL_2017_001_R\>

| **OJ**                                                       | **Acts**                                                                                 | **TOC**                                                            | **Signature**                                                      |
|--------------------------------------------------------------|------------------------------------------------------------------------------------------|--------------------------------------------------------------------|--------------------------------------------------------------------|
| http:// publications. europa.eu/ resource/oj/ JOL_2017_001_R | [http://publications.](http://publications/) europa.eu/ resource/oj/ JOL_2017_001_R_0002 | http:// publications. europa.eu/ resource/oj/ JOL_2017_001_R\_ TOC | http:// publications. europa.eu/ resource/oj/ JOL_2017_001_R\_ SIG |
| http:// publications. europa.eu/ resource/oj/ JOL_2017_001_R | [http://publications.](http://publications/) europa.eu/ resource/oj/ JOL_2017_001_R_0001 | http:// publications. europa.eu/ resource/oj/ JOL_2017_001_R\_ TOC | http:// publications. europa.eu/ resource/oj/ JOL_2017_001_R\_ SIG |

![](8334caa65ce9174619382b9cbd882e42.png)

##### Getting the table of acts and signatures in the scope of OJ Act by Act related to a specific date of publication as of October 2023

**Scenario:** you want to get all the work URIs (acts and signatures) related to a specific date of publication.

**Solution:** This can be done in SPARQL with the query shown in Table 12. There are as many result rows as acts, shown in Table 13.

**Table 12: SPARQL query for getting the URIs of acts and signatures for a specific date of publication**

**Table 13: Part of the Results of SPARQL query of Table 12, with the URIs of acts and their signatures for the publication date "2023-10-02"**

| **Acts**                                                                                                        | **Signature**                                                                                                           |
|-----------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| [http://publications.europa.eu/ resource/oj/C_202300002](http://publications.europa.eu/resource/oj/C_202300002) | [http://publications.europa.eu/resource/oj/ C_202300002_SIG](http://publications.europa.eu/resource/oj/C_202300002_SIG) |
| [http://publications.europa.eu/ resource/oj/C_202300005](http://publications.europa.eu/resource/oj/C_202300005) | [http://publications.europa.eu/resource/oj/ C_202300005_SIG](http://publications.europa.eu/resource/oj/C_202300005_SIG) |

![](a742586b1a6331a3e480e49c75e53171.png)

### Download a part or the whole of the repository

**Scenario:** you want to download all or part of the Cellar.

**Solution:** given the possibilities of Cellar interfaces, it is possible to download everything from it, but be warned, it is big. As of July 2023, there were:

-   1 billion triples (that is, 1.6 x 10 ),9
-   46 million files,
-   And getting an average of 22 million hits per day, that is, more than 255 hits per second.

    The point of having semantic technologies is precisely not needing to download anything and trusting the author, who will keep everything online and updated. You can model your data and link to the Cellar (see section 2).

    There is no single list or catalogue on the publications, except by collections, which can be consulted in the corresponding portals, like EUR-Lex or the

    EU-Bookshop. However, you can make general queries in the SPARQL endpoint, but more general queries take much more time to process.

    From either source, and with some links ready, you may download documents one by one, or automate the process. In any case, please take into account Section 1.5: service level agreement.

    Often, we receive questions on filtering or customising some extractions.

    It is impossible for the OP to fulfil all kinds of requests. Nonetheless we will be happy to extend this document to answer the most common needs and provide examples.

### Old license holder extractions at the OP

**Scenario:** in the past, the OP had contracts with license holders who paid for specific extraction notices, made available in an FTP server. As the reuse Decision came into force (see footnote 1), the contracts were terminated. These extractions were phased out for the following reasons.

-   The extractions were not complete, or at least not as complete as the SPARQL or the RESTful API. The reason: there are updates after the extractions to the FTP.
-   The extractions were a non-standard interface.
-   The insecurity inherent to an FTP server.

![](8334caa65ce9174619382b9cbd882e42.png)

**Solution**: do the following steps:

1.  Get RSS notifications (see section 5.2.3) with wemiClasses=work, other parameters as you need. This will retrieve references like:

    **Table 14: Example of an RSS extraction of a work**

2.  For every item above, take the \<guid\> tag (in the example, cellar:b768d303- 9301-11e7-b92d-01aa75ed71a1) and get the XML branch notice of the publication in the language required (see section 5.2.1.2).

    The result will be as follows:

**Table 15: Example of a branch notice extraction**

![](a742586b1a6331a3e480e49c75e53171.png)

### Case-law

**Scenario:** how can you get the case-law collection? Filter: title (when available) in English, European case-law identifier (ECLI), divided into four classes:

-   Documents CJ EU: contains the whole sector (16) 6+8 (documents from the Court, from the National Courts, notices published in the OJ, evolutive works).
-   Summary Case Law: short version of the documents from the Court.
-   Summary Case Law Jure: short version of the documents from the National Courts.
-   Case reports.

    **Solution:** use the SPARQL query in Table 14. Also, if you are only interested in one of the classes, you may remove the others from the FILTER query line.

**Table 16: SPARQL query to get case-law in English, with class and ECLI**

The startup OpenLaws is enriching (17) justice documents targeting citizens, businesses and legal experts with a new platform called \<[http://openlaws.eu](http://openlaws.eu/)\>. It uses SPARQL to get the notice references, and then the RESTful interface to get the metadata in RDF and the contents.

1.  For more information on sectors, please refer to the FAQ from EUR-Lex: [http://eur-lex.europa.eu/content/help/faq/intro.html\#help9](http://eur-lex.europa.eu/content/help/faq/intro.html#help9)
2.  <https://zenodo.org/record/158999/files/D4.4.d3%20BOLD%20Vision.pdf>

![](8334caa65ce9174619382b9cbd882e42.png)

### EU treaties

**Scenario:** how can you get all EU treaties?

**Solution:** use the SPARQL query in Table 17.

**Table 17: SPARQL query to get all EU treaties**

### EU legislation in force about climate change

**Scenario:** what is the EU legislation in force about the Eurovoc concept ‘climate change’?

**Solution:** use the SPARQL query in Table 18.

**Table 18: SPARQL query to get all EU legislation in force about climate change**

Other examples are the projects Jurion (18) and Aligned (19), which are enriching the EU legislation. They use SPARQL to get the notice references, and then the RESTful interface to get the metadata in RDF and the contents.

The project api.epdb.eu (20) is also reusing EU legislation and pre-legislation in the same way, but for providing a new API to access it. Check its website for examples on code used and visualisation.

1.  <http://jurion.de/>
2.  <http://aligned-project.eu/>
3.  <http://api.epdb.eu/>

# PART II:

**Technical reference**

![](dc1b910738f55de9484b891a49f9fda5.png)

## RESTful and RSS API

### Main concepts

Here follows a description of the main concepts on which the Cellar data model is built upon:

− Functional Requirements for Bibliographic Records (FRBR) – paragraph 5.1.1

− Types of notices – paragraph 5.1.2

− Content streams – paragraph 5.1.3

− NALs – paragraph 5.1.4

− Eurovoc – paragraph 5.1.5

− Resource URI – paragraph 5.1.6.

##### Functional requirements for bibliographic records (frbr)

Functional Requirements for Bibliographic Records (FRBR) is a conceptual entity-relationship model developed by the International Federation of Library

Associations and Institutions (IFLA) that relates user tasks of retrieval and access in online library catalogues and bibliographic databases from a user’s perspective.

The FRBR comprises 3 groups of entities.

The group 1 entities are the Work, Expression, Manifestation, and Item (WEMI): they represent the products of intellectual or artistic endeavour, and are the foundation of the FRBR model.

Here follows a description of each:

− the Work is generally defined as a distinct intellectual or artistic creation. Example: Beethoven's Ninth Symphony apart from all ways of expressing it is a work

− the Expression is the specific intellectual or artistic form that a work takes each time it is 'realized'. Example: an expression of Beethoven's Ninth might be the musical score he wrote down

− the Manifestation is the physical embodiment of an expression of a work.

As an entity, manifestation represents all the physical objects that bear the same characteristics, in respect to both intellectual content and physical form. Example: the recording the London Philharmonic made of the Ninth in 1996 is a manifestation

− the Item is a single exemplar of a manifestation. The entity defined as item is a concrete entity. Example: each of the 1996 pressings of that 1996 recording is an item.

The group 2 entities are Person and Corporate body, responsible for the custodianship of Group 1’s intellectual or artistic endeavor.

The group 3 entities are subjects of Group 1 or Group 2’s intellectual endeavour, and include Concepts, Objects, Events and Places.

![](91bfec9f26742edb5044e7b00579d78e.png)

##### FRBR in Cellar's context

For what concerns its use in the Cellar, the essential idea of FRBR is to present a publication at different levels of abstraction. In order to accomplish this, the

Cellar realizes the WEMI pattern through three different hierarchies, each with its own levels of abstraction.

##### Hierarchy work-expression-manifestation-content stream

The work-expression-manifestation-content stream hierarchy (see Figure 7) is composed by:

− a work, which covers the W role of the WEMI pattern. A work may embed:

− several expressions. An expression covers the E role of the WEMI pattern, and is defined as the realization of a work in a specific language. It may embed:

− several manifestations. A manifestation covers the M role of the WEMI pattern, and is defined as the instantiation of a work in the language defined by the embedding expression, and in a specific format. Finally, a manifestation may embed:

− several content streams. A content stream covers the I role of the WEMI pattern, and is defined as the entity that physically carries the information of the manifestation. The content stream is typically a document written in the language and format defined by the embedding manifestation.

**Figure 8: The work-expression-manifestation-content stream hierarchy**

![](8375a77c604f2e2994caf52dc726989b.png)

![](dc1b910738f55de9484b891a49f9fda5.png)

The Cellar contains works from the OP's primary domains of work:

− Legislative data, currently published primarily in the EUR-Lex portal

− General publications, currently published in EU Publications portal In the future, also:

− Tender documents and related works (OJ-S), currently published in TeD portal

− Research documents, currently published in the CORDIS portal

The WEMI model is applied consistently throughout for works from all domains. However, the abstract classes such as works are then concretized for the various domains in the Cellar's Common Data Model (CDM) by subclassing these abstract classes. The full set of subclasses is documented in the CDM's web page. See section 6.1.

##### Hierarchy dossier-event

The dossier-event hierarchy (see Figure 8) is composed by:

− a dossier, which covers the W role of the WEMI pattern. A dossier may embed:

− several events, which cover the E role of the WEMI pattern.

**Figure 9: The dossier-event hierarchy**

As for works, dossiers can have specializations for each of the domains. At present there are such specializations for legislative procedures with and without inter-institutional codes to classify legislative procedures. There are also classifications for different types of events that can occur in a procedure.

##### Hierarchy event

The event also called top level event hierarchy is solely composed by an event, which covers the W role of the WEMI pattern. It’s a new hierarchy: now an event can be a top level entity and not only a child of a “Dossier”.

##### Hierarchy agent

The agent hierarchy is solely composed by an agent, which covers the W role of the WEMI pattern.

![](91bfec9f26742edb5044e7b00579d78e.png)

##### Types of notices

We present hereby the concept of notice, which can be subsequently divided into 5 types: tree-, branch-, object-, identifier- and rdf-notice.

For the sake of simplicity, the explanations below refer to the work-expression- manifestation-content stream hierarchy, but they can be considered valid also for the dossier-event, top level event and agent hierarchy.

##### Tree notice

A Tree notice is an XML document including:

− the work’s metadata

− all available expressions’ metadata

− all available manifestations’ metadata for each expression.

All metadata is decoded in the given decoding language, that is, the language used for notices to decode NAL and Eurovoc concepts into the specific natural language. For more information about NAL and Eurovoc concepts, please consult paragraphs 5.1.4 and 5.1.5.

For more information about how to retrieve a tree notice and its format, please see paragraph 5.2.1.1.

##### Branch notice

A Branch notice is a content language specific XML document including:

− the work’s metadata

− the metadata of the expression in the given content language

− all available manifestations’ metadata for that expression. All metadata is decoded in the given decoding language.

It is a subset of the Tree Notice.

For more information about how to retrieve a branch notice and its format, please see paragraph 5.2.1.2.

##### Object notice

An Object notice is a content language specific XML document with the metadata for a specific resource (work/expression/manifestation).

The metadata is decoded in the given decoding language.

It is a subset of the Tree Notice because only one object is in scope, while hierarchically dependent objects are not included (e.g. an expression, but not its manifestations).

For more information about how to retrieve an object notice and its format, please see paragraphs 5.2.1.3, 5.2.1.4 and 5.2.1.5.

![](dc1b910738f55de9484b891a49f9fda5.png)

##### Identifier notice

An Identifier notice is an XML document containing the synonyms of a list of resource URIs.

For a definition of resource URI, please see paragraph 5.1.6.

For more information about how to retrieve an identifier notice and its format, please see paragraph 5.2.1.6.

##### RDF-Object notice

An RDF-Object notice is the RDF/XML notice format for a specific resource (work/ expression/manifestation).

For more information about how to retrieve an RDF-Object notice and its format, please see paragraph 5.2.1.7.

##### RDF-Tree notice

An RDF-Tree notice is the RDF/XML notice format for the tree whose root is a specific resource (work).

For more information about how to retrieve an RDF-Tree notice and its format, please see paragraph 5.2.1.7.

##### Content streams

The content stream physically carries the information of the manifestation that embeds it. It realizes the item of the WEMI pattern (see also paragraph 5.1.1.1).

Typically, it is a document written in the content language and format defined by the embedding manifestation: for instance, it may represent the PDF document Official Journal of the European Union C 318, Volume 52, English edition.

For more information about how to retrieve a content stream, please see paragraph 5.2.1.9.

##### NALs

The NALs (Named Authority List) are a preloaded, not modifiable, decoded-by- language set of data meant to be used by the Cellar ontology’s concepts. The NAL itself is a concept defined with the resource URI:

<http://publications.europa.eu/resource/authority/>\*

where \* is the NAL specific class.

One exception is Eurovoc, which is defined at:

<http://eurovoc.europa.eu/100141>

![](91bfec9f26742edb5044e7b00579d78e.png)

##### Eurovoc

Eurovoc is the multilingual thesaurus maintained by the Publications Office of the European Union.

It exists in all the official languages of the European Union. Eurovoc is used by:

− the European Parliament

− the Publications Office of the European Union

− the national and regional parliaments in Europe

− some national government departments and European organisations.

This thesaurus serves as the basis for the domain names used in the European Union's terminology database: Inter-Active Terminology for Europe.

As stated in previous paragraph, the Eurovoc is one specific type of NAL.

##### Resource URI

Each resource in the CELLAR is globally identified by a URI composed as follows: <http://publications.europa.eu/resource/>{ps-name}/{ps-id} From now on, we will refer to this URI as the resource URI.

Here follows a description of each part of the resource URI (paragraphs 5.1.6.1 and 5.1.6.2), with some examples depicted in paragraph 5.1.6.3. Finally, paragraph 5.1.6.4 describes the CURIE format.

##### {PS-NAME}

It identifies the name of the production system.

The CELLAR currently (21) uses the following production system names:

cellar, celex, oj, com, genpub, ep, jurisprudence, dd, mtf, consolidation, eurostat, eesc, cor, nim, pegase, agent, uriserv, join, swd, comnat, mdr, legissum, ecli, procedure, procedure-event, eli, immc, planjo, numpub, case-event, case, person, organization, whoiswho, membership, consil, dataset, documentation, directory, distribution, schema, expression, jure, parliament, eca, wp, intproc, intproc-event, intcom, inteesc, intcor, intconsil, intep, inteca, ecb, ted, session, session-sitting, legispack, dossier, dossier-event, transjai, pi_com, internal_proc, internal_proc-event, pi_eca, pi_ep, pi_consil, pi_cor, pi_eesc, ontology, eescarch, serpub, issn, location and budget.

##### {PS-ID}

It is the resource’s unique identifier, and it has a structure that depends on the value of {ps-name}.

1.  This list is not exhaustive and is revised regularly.

![](dc1b910738f55de9484b891a49f9fda5.png)

1.  *If {ps-name} is ‘cellar’*

    cellar is the only production system’s name reserved to the Cellar application, and its identifiers follow the following conventions:

**Table 19: Identifier’s conventions for production system name cellar**

| **Type**                 | {ps-id}                               | **Example**                                        |
|--------------------------|---------------------------------------|----------------------------------------------------|
| work dossier event agent |   {work-id}                           |   b84f49cd-750f-11e3-8e20-01aa75ed71a1             |
| expression               | {work-id}.{expr-id}                   | b84f49cd-750f-11e3-8e20-01aa75ed71a1.0001          |
| manifestation            | {work-id}.{expr-id}. {man-id}         | b84f49cd-750f-11e3-8e20-01aa75ed71a1.0001.03       |
| content stream           | {work-id}.{expr-id}. {man-id}/{cs-id} | b84f49cd-750f-11e3-8e20-01aa75ed71a1.0001.03/DOC_1 |

where:

− {work-id} is a valid Universally Unique Identifier (UUID)

− {expr-id} is a 4-chars numeric value

− {man-id} is a 2-chars numeric value

− {cs-id} is an alphanumeric value with following pattern: DOC_x, where x is an incremental numeric value that identifies the content stream.

1.  *If {ps-name} is other than ‘cellar’*

    For all other production system’s names, the following conventions are used:

    **Table 20: Identifier’s conventions for production system names other than cellar**

| **Type**           | {ps-id}                               | **Example**                                   |
|--------------------|---------------------------------------|-----------------------------------------------|
| work dossier agent |  {work-id}                            |  32006D0241                                   |
| expression         | {work-id}.{expr-id}                   | 32006D0241.FRA                                |
| manifestation      | {work-id}.{expr-id}. {man-id}         | 32006D0241.FRA.fmx4                           |
| content stream     | {work-id}.{expr-id}. {man-id}.{cs-id} | 32006D0241.FRA. fmx4.L_2006088FR.01006402.xml |
| event              | {work-id}.{event- id}                 | 11260.12796                                   |

![](91bfec9f26742edb5044e7b00579d78e.png)

where:

− {work-id} is an alphanumeric value

− {expr-id} is a 3-chars ISO_639-3 language code. For the exhaustive list of supported ISO_639-3 codes, please refer to paragraph 5.4.1.

− {man-id} is an alphanumeric value identifying a file format (Formex, PDF, HTML, XML, etc.)

− {cs-id} is an alphanumeric value identifying the name of the content stream

− {event-id} is a numeric value.

##### Examples of valid resource URIs

Here follows a non-exhaustive list of examples of resource URIs that match the patterns described above:

1.  The following resource URI identifies a work with ps-name of type cellar and the given ps-id: <http://publications.europa.eu/resource/cellar/b84f49cd-> 750f-11e3-8e20-01aa75ed71a1
2.  The following resource URI identifies an expression – belonging to the work at point 1) – with ps-name of type cellar and the given ps-id: <http://publications.europa.eu/resource/cellar/b84f49cd-> 750f-11e3-8e20-01aa75ed71a1.0006
3.  The following resource URI identifies a manifestation – belonging to the expression at point 2) - with ps-name of type cellar and the given ps-id: <http://publications.europa.eu/resource/cellar/b84f49cd-> 750f-11e3-8e20-01aa75ed71a1.0006.03
4.  The following resource URI identifies a content stream – belonging to the manifestation at point 3) – with ps-name of type cellar and the given ps-id: <http://publications.europa.eu/resource/cellar/b84f49cd-> 750f-11e3-8e20-01aa75ed71a1.0006.03/DOC_1
5.  The following resource URI identifies a work with ps-name of type oj and the given ps-id: <http://publications.europa.eu/resource/oj/JOL_2014_001_R_0001_01>
6.  The following resource URI identifies a work with ps-name of type celex and the given ps-id: <http://publications.europa.eu/resource/celex/32014R0001>
7.  The following resource URI identifies an expression – belonging to the work at point 6) - with ps-name of type celex and the given ps-id: <http://publications.europa.eu/resource/celex/32014R0001.FRA>
8.  The following resource URI identifies a manifestation – belonging to the expression at point 7) - with ps-name of type oj and the given ps-id: <http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01.FRA.fmx4

![](dc1b910738f55de9484b891a49f9fda5.png)

1.  The following resource URI identifies a content stream – belonging to the manifestation at point 8) - with ps-name of type oj and the given ps-id: <http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01.FRA.fmx4.L_2014001FR.01000302.xml
2.  The following resource URI identifies a work with ps-name of type pegase and the given ps-id: <http://publications.europa.eu/resource/pegase/11260>
3.  The following resource URI identifies an event with ps-name of type pegase and the given ps-id: <http://publications.europa.eu/resource/pegase/11260.12796>

##### CURIE format of a resource URI

For practical reasons, resource URIs are abbreviated onto a CURIE (Compact URI) format. This is done by making the production system name the alias of the system base URI.

For example, by declaring the namespace xmlns:celex=<http://publications.europa.eu/resource/celex/> we can abbreviate <http://publications.europa.eu/resource/celex/1234R5678> onto

celex:1234R5678

This CURIE format is important as it is massively used for identifying objects in Cellar’s notices (for more info about Cellar’s notices’ format, please see paragraph 5.2.1).

### Available services

The Cellar API allows performing different operations on the Cellar. Such API encapsulates all the HTTP calls to the Cellar and exposes convenience methods allowing the user to easily retrieve the requested content.

It is hereby described how to invoke services on WEMI objects, namely:

− retrieve the tree notice of a work – see paragraph 5.2.1.1

− retrieve the branch notice of a work – see paragraph 5.2.1.2

− retrieve the object notice of an object (work, expression or manifestation) – see paragraphs 5.2.1.3, 5.2.1.4 and 5.2.1.5.

− retrieve all the identifiers of a specific document (synonyms) – paragraph 5.2.1.6

− retrieve the RDF/XML formatted metadata for a given resource – paragraph 5.2.1.7

− retrieve the RDF/XML formatted metadata for the tree whose root is a given resource – paragraph 5.2.1.8

![](91bfec9f26742edb5044e7b00579d78e.png)

− retrieve content streams of a work given a specific language and format – paragraph 5.2.1.9

and how to invoke services on NAL/Eurovoc objects, namely:

− retrieve a dump – paragraph 5.2.2.1

− retrieve the supported languages – paragraph 5.2.2.2

− retrieve a concept scheme – paragraph 5.2.2.3

− retrieve the concept schemes – paragraph 5.2.2.4

− retrieve a concept – paragraph 5.2.2.5

− retrieve the concept relatives – paragraph 5.2.2.6

− retrieve the top concepts – paragraph 5.2.2.7

− retrieve the domains – paragraph 5.2.2.8.

The next sections explain how to use these services, each of which is described through the following sections:

− **description**: a short description of what the service is supposed to do

− **request**, where are described:

-   the URL to invoke and its type (GET or POST)
-   the URL parameters, if any. Please note that all parameters representing an HTTP URL themselves must be URL-encoded, for example: http%3A%2F%2Fpublications.europa.eu%2Fresource%2Fauth ority%2Ffd_330

    If not specified otherwise, a parameter is always mandatory

-   the HTTP headers, if any
-   a list of examples of valid requests.

    − **response**: what the response is supposed to contain, its format, and an example of it.

##### WEMI services

We describe hereby the available services for retrieving the information related to the WEMI objects. For simplicity, they are described for the work-expression- manifestation-content stream hierarchy, but they can be considered valid also for the dossier-event, topLevelEvent and agent hierarchy (see paragraph 5.2.1.1).

Dissemination service uses a global negotiation system that returns always a “303 – See other” response. The client must enable the follow-redirect option.

![](dc1b910738f55de9484b891a49f9fda5.png)

##### Retrieve the tree notice

**Description**

This service allows the user to search for a complete tree notice of a given work, decoded in the given decoding language.

The returned notice will contain the work metadata, the metadata of all the expressions associated to the work, and the metadata of all the manifestations associated to the expressions.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}&filter={in_notice-only}

where:

− {ps-name} is a valid production system name (see also paragraph 5.1.6.1)

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name} (see also paragraph 5.1.6.2)

− {dec-lang} is a 3-chars ISO_639-3 language code identifying the decoding language to use: this is the language used for decoding the NALs associated to the notice. If decoding language is not available, the default value defined in the configuration is used.

− {in_notice-only} is an optional boolean that indicates if the notice contains only the properties annotated with in_notice.

*Please note:* no matter what the request specifies, the response notice is always the filtered one. The filter parameter will stay for a transition period due to legacy reasons.

The following HTTP headers must be set on the request:

− Accept:application/xml;notice=tree

Here follows some examples of valid requests using cURL:

− curl -H 'Accept:application/xml;notice=tree' http:// publications.europa.eu/resource/cellar/b84f49cd-750f-11e3-8e20- 01aa75ed71a1?language=eng -L

− curl -H 'Accept:application/xml;notice=tree' http:// publications.europa.eu/resource/oj/JOL_2014_001_R_0001_01? language=eng -L

− curl -H 'Accept:application/xml;notice=tree' <http://publications.europa.eu/resource/> celex/32014R0001?language=eng -L

Please note that the 3 requests use different production system names and identifiers, but actually retrieve the same work. These 3 synonyms are related to the same cellar id.

![](91bfec9f26742edb5044e7b00579d78e.png)

**Response**

The response is an XML-formatted tree notice containing the full hierarchy of the work, here included all the expressions of the work and all the manifestations associated to the expressions.

Here follows an example of returned notice (only the relevant information is reported):

\<NOTICE decoding="eng" type="tree"\>

\<WORK\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1\</VALUE\>

\<IDENTIFIER\>b84f49cd-750f-11e3-8e20-01aa75ed71a1\</

IDENTIFIER\>

\<TYPE\>cellar\</TYPE\>

\</URI\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/> resource/celex/32014R0001\</VALUE\>

\<IDENTIFIER\>32014R0001\</IDENTIFIER\>

\<TYPE\>celex\</TYPE\>

\</URI\>

\</SAMEAS\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/> resource/oj/JOL_2014_001_R_0001_01\</VALUE\>

\<IDENTIFIER\>JOL_2014_001_R_0001_01\</

IDENTIFIER\>

\<TYPE\>oj\</TYPE\>

\</URI\>

\</SAMEAS\> [...]

\</WORK\> [...]

\<EXPRESSION\>

[content of expression 0001]

\<EXPRESSION\>

\<MANIFESTATION\>

[content of manifestation 0001.01]

\<MANIFESTATION\>

\<MANIFESTATION\>

[content of manifestation 0001.02]

\<MANIFESTATION\> [...]

\<MANIFESTATION\>

[content of manifestation 0001.M]

\<MANIFESTATION\>

![](dc1b910738f55de9484b891a49f9fda5.png)

\<EXPRESSION\>

[content of expression 0002]

\<EXPRESSION\>

\<MANIFESTATION\>

[content of manifestation 0001.01]

\<MANIFESTATION\>

\<MANIFESTATION\>

[content of manifestation 0002.02]

\<MANIFESTATION\> [...]

\<MANIFESTATION\>

[content of manifestation 0002.M]

\<MANIFESTATION\> [...]

\<EXPRESSION\>

[content of expression N]

\<EXPRESSION\>

\<MANIFESTATION\>

[content of manifestation N.01]

\<MANIFESTATION\>

\<MANIFESTATION\>

[content of manifestation N.02]

\<MANIFESTATION\> [...]

\<MANIFESTATION\>

[content of manifestation N.M]

\<MANIFESTATION\>

\</NOTICE\>

##### Retrieve the branch notice

**Description**

This service allows the user to search for a complete branch notice of a given work, decoded in the given decoding language.

The returned notice will contain the work metadata, the metadata of the expression in the given accept language, and the metadata of all manifestations associated to the expression.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}&filter={in_notice-only}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

![](91bfec9f26742edb5044e7b00579d78e.png)

− {dec-lang} is a 3-chars ISO_639-3 language code identifying the decoding language to use: this is the language used for decoding the NALs associated to the notice. If decoding language is not available, the default value defined in the configuration is used.

− {in_notice-only} is an optional boolean that indicates if the notice contains only the properties annotated with in_notice.

Please note: no matter what the request specifies, the response notice is always the filtered one. The filter parameter will stay for a transition period due to legacy reasons.

The following HTTP headers must be set on the request:

− Accept:application/xml;notice=branch

− Accept-Language:{acc-lang}, where {acc-lang} is a 3-chars ISO_639-3 language code identifying the accept language to use: this will be used for retrieving the correct expression.

Here follows some examples of valid requests that retrieve the same object, using cURL:

− curl -H 'Accept:application/xml;notice=branch' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/cellar/> b84f49cd-750f-11e3-8e20-01aa75ed71a1?language=eng -L

− curl -H 'Accept:application/xml;notice=branch' -H 'Accept- Language:fra' [http://publications.europa.eu/resource/oj/JOL\_](http://publications.europa.eu/resource/oj/JOL_) 2014_001_R_0001_01?language=en -L

− curl -H 'Accept:application/xml;notice=branch' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/> celex/32014R0001?language=eng -L

**Response**

The response is an XML-formatted branch notice containing the work, within the expression in the given accept language, and all the associated manifestations.

Here follows an example of returned notice:

\<NOTICE decoding="eng" type="branch"\>

\<WORK\>

\<URI\>

\<VALUE\> <http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1\</VALUE\>

\<IDENTIFIER\> b84f49cd-750f-11e3-8e20-01aa75ed71a1

\</IDENTIFIER\>

\<TYPE\>cellar\</TYPE\>

\</URI\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> celex/32014R0001\</VALUE\>

![](dc1b910738f55de9484b891a49f9fda5.png)

\<IDENTIFIER\>32014R0001\</IDENTIFIER\>

\<TYPE\>celex\</TYPE\>

\</URI\>

\</SAMEAS\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01\</VALUE\>

\<IDENTIFIER\>JOL_2014_001_R_0001_01\</IDENTIFIER\>

\<TYPE\>oj\</TYPE\>

\</URI\>

\</SAMEAS\> [...]

\</WORK\> [...]

\<EXPRESSION\>

[content of expression X in given language {acc-lang}]

\<EXPRESSION\>

\<MANIFESTATION\>

[content of manifestation X.01]

\<MANIFESTATION\>

\<MANIFESTATION\>

[content of manifestation X.02]

\<MANIFESTATION\> [...]

\<MANIFESTATION\>

[content of manifestation X.M]

\<MANIFESTATION\>

\</NOTICE\>

##### Retrieve the object work notice

**Description**

This service allows the user to search for the object notice of the given work, decoded in the given decoding language.

Only the metadata of the work are returned in the notice, with no expression or manifestation.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}&filter={in_notice-only}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

![](91bfec9f26742edb5044e7b00579d78e.png)

− {dec-lang} is a 3-chars ISO_639-3 language code identifying the decoding language to use: this is the language used for decoding the NALs associated to the notice. If decoding language is not available, the default value defined in the configuration is used.

− {in_notice-only} is an optional boolean that indicates if the notice contains only the properties annotated with in_notice.

*Please note:* no matter what the request specifies, the response notice is always the filtered one. The filter parameter will stay for a transition period due to legacy reasons.

The following HTTP headers must be set on the request:

− Accept:application/xml;notice=object

Here follows some examples of valid requests that retrieve the same object, using cURL:

− curl -H 'Accept:application/xml;notice=object' http:// publications.europa.eu/resource/cellar/b84f49cd-750f- 11e3-8e20-01aa75ed71a1?language=eng -L

− curl -H 'Accept:application/xml;notice=object' http:// publications.europa.eu/resource/oj/JOL_2014_001_R_0001_01? language=eng -L

− curl -H 'Accept:application/xml;notice=object' <http://publications.europa.eu/resource/> celex/32014R0001?language=eng -L

**Response**

The response is an XML-formatted object notice containing the metadata of the work only.

Here follows an example of returned notice:

\<NOTICE decoding="eng" type="object"\>

\<WORK\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1\</VALUE\>

\<IDENTIFIER\>b84f49cd-750f-11e3-8e20-01aa75ed71a1\</ IDENTIFIER\>

\<TYPE\>cellar\</TYPE\>

\</URI\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> celex/32014R0001\</VALUE\>

\<IDENTIFIER\>32014R0001\</IDENTIFIER\>

\<TYPE\>celex\</TYPE\>

\</URI\>

\</SAMEAS\>

![](dc1b910738f55de9484b891a49f9fda5.png)

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> oj/JOL_2014_001_R_0001_01\</VALUE\>

\<IDENTIFIER\>JOL_2014_001_R_0001_01\</IDENTIFIER\>

\<TYPE\>oj\</TYPE\>

\</URI\>

\</SAMEAS\> [...]

\</WORK\> [...]

\</NOTICE\>

##### Retrieve the object.expression notice

**Description**

This service allows the user to search for the expression of the given work, decoded in the given decoding language.

The returned notice will contain the metadata of the expression in the given accept language, with no metadata of the work or manifestations.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}&filter={in_notice-only}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

− {dec-lang} is a 3-chars ISO_639-3 language code identifying the decoding language to use: this is the language used for decoding the NALs associated to the notice. If decoding language is not available, the default value defined in the configuration is used.

− {in_notice-only} is an optional boolean that indicates if the notice contains only the properties annotated with in_notice.

*Please note:* no matter what the request specifies, the response notice is always the filtered one. The filter parameter will stay for a transition period due to legacy reasons.

The following HTTP headers must be set on the request:

− Accept:application/xml;notice=object

− Accept-Language:{acc-lang}, where {acc-lang} is a 3-chars ISO_639-3 language code identifying the accept language to use: this will be used for retrieving the correct expression.

![](91bfec9f26742edb5044e7b00579d78e.png)

Here follows some examples of valid requests that retrieve the same object, using cURL:

− curl -H 'Accept:application/xml;notice=object' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1?language=eng -L

− curl -H 'Accept:application/xml;notice=object' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/oj/JO> L_2014_001_R_0001_01?language=eng -L

− curl -H 'Accept:application/xml;notice=object' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/> celex/32014R0001?language=eng -L

**Response**

The response is an XML-formatted object notice containing the metadata of the expression only.

Here follows an example of returned notice:

\<NOTICE decoding="eng" type="object"\>

\<EXPRESSION\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1.0010\</VALUE\>

\<IDENTIFIER\>b84f49cd-750f-11e3-8e20-01aa75ed71a1.0010\</ IDENTIFIER\>

\<TYPE\>cellar\</TYPE\>

\</URI\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> celex/32014R0001.FRA\</VALUE\>

\<IDENTIFIER\>32014R0001.FRA\</IDENTIFIER\>

\<TYPE\>celex\</TYPE\>

\</URI\>

\</SAMEAS\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> uriserv/OJ.L_.2014.001.01.0001.01.FRA\</VALUE\>

\<IDENTIFIER\>OJ.L_.2014.001.01.0001.01.FRA\</IDENTIFIER\>

\<TYPE\>uriserv\</TYPE\>

\</URI\>

\</SAMEAS\> [...]

\</EXPRESSION\>

\</NOTICE\>

![](dc1b910738f55de9484b891a49f9fda5.png)

##### Retrieve the object manifestation notice

**Description**

This service allows the user to search for the object notice of the given manifestation, decoded in the given decoding language.

Only the metadata of the manifestation are returned in the notice, with no work or expressions.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}&filter={in_notice-only}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a manifestation, and compatible with its {ps-name}

− {dec-lang} is a 3-chars ISO_639-3 language code identifying the decoding language to use: this is the language used for decoding the NALs associated to the notice. If decoding language is not available, the default value defined in the configuration is used.

− {in_notice-only} is an optional boolean that indicates if the notice contains only the properties annotated with in_notice.

*Please note:* no matter what the request specifies, the response notice is always the filtered one. The filter parameter will stay for a transition period due to legacy reasons.

The following HTTP headers must be set on the request:

− Accept:application/xml;notice=object

The following HTTP header can be set on the request:

− Negotiate:vlist

If it is present, the response will include an Alternates header indicating all alternative representations of the returned object

Here follows some examples of valid requests that retrieve the same object, using cURL:

− curl -H 'Accept:application/xml;notice=object' http:// publications.europa.eu/resource/cellar/b84f49cd-750f- 11e3-8e20-01aa75ed71a1.0010.03?language=eng -L

− curl -H 'Accept:application/xml;notice=object' <http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01.FRA.xhtml?language=eng -L

![](91bfec9f26742edb5044e7b00579d78e.png)

− curl -H 'Accept:application/xml;notice=object' http:// publications.europa.eu/resource/celex/32014R0001.FRA. print?language=eng -L

**Response**

The response is an XML-formatted object notice containing the metadata of the manifestation only.

Here follows an example of returned notice:

\<NOTICE decoding="eng" type="object"\>

\<MANIFESTATION manifestation-type="xhtml"\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1.0010.03\</VALUE\>

\<IDENTIFIER\>b84f49cd-750f-11e3-8e20- 01aa75ed71a1.0010.03\</IDENTIFIER\>

\<TYPE\>cellar\</TYPE\>

\</URI\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01.FRA.xhtml\</VALUE\>

\<IDENTIFIER\>JOL_2014_001_R_0001_01.FRA.xhtml\</ IDENTIFIER\>

\<TYPE\>oj\</TYPE\>

\</URI\>

\</SAMEAS\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> uriserv/OJ.L_.2014.001.01.0001.01.FRA.xhtml\</VALUE\>

\<IDENTIFIER\>OJ.L_.2014.001.01.0001.01.FRA.xhtml\</ IDENTIFIER\>

\<TYPE\>uriserv\</TYPE\>

\</URI\>

\</SAMEAS\>

\<MANIFESTATION_TYPE type="data"\>

\<VALUE\>xhtml\</VALUE\>

\</MANIFESTATION_TYPE\> [...]

\</MANIFESTATION\>

\</NOTICE\>

##### Retrieve the identifier notice

**Description**

This service allows the user to retrieve the synonyms of a given resource URI.

![](dc1b910738f55de9484b891a49f9fda5.png)

**Request**

The user must fire a GET request to the following URL: <http://publications.europa.eu/resource/>{ps-name}/{ps-id} where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, an expression, a manifestation, an item, a dossier, an event, a top level event or an agent and is compatible with its {ps-name}

The following HTTP header must be set on the request:

− Accept:application/xml;notice=identifiers

Here follow some examples of valid requests that retrieve different objects, using cURL:

− curl -H 'Accept:application/xml;notice=identifiers' <http://publications.europa.eu/resource/cellar/b84f49cd-> 750f-11e3-8e20-01aa75ed71a1 -L

− curl -H 'Accept:application/xml;notice=identifiers' http:// publications.europa.eu/resource/celex/32014R0001.FRA.print -L

− curl -H 'Accept:application/xml;notice=identifiers' http:// publications.europa.eu/resource/oj/JOL_2014_001_R_0001_01.FRA. fmx4.L_2014001FR.01000101.xml -L

− curl -H 'Accept:application/xml;notice=identifiers' http:// publications.europa.eu/resource/oj/JOL_2006_088_R_0063_01.FRA. fmx4.L_2006088FR.01006301.xml -L

− curl -H 'Accept:application/xml;notice=identifiers' http:// publications.europa.eu/resource/pegase/11260.12796 -L

**Response**

The response is an XML-formatted notice containing the URI of the cellar ID and its synonym(s).

\<?xml version="1.0" encoding="UTF-8"?\>

\<NOTICE type="identifier"\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> cellar/32a58fc1-cffa-11e1-96ce-01aa75ed71a1.0003\</VALUE\>

\<TYPE\>cellar\</TYPE\>

\<IDENTIFIER\>32a58fc1-cffa-11e1-96ce-01aa75ed71a1.0003\</ IDENTIFIER\>

\</URI\>

\<SAMEAS\>

\<URI\>

\<VALUE\><http://publications.europa.eu/resource/> pegase/11260.12796\</VALUE\>

![](91bfec9f26742edb5044e7b00579d78e.png)

\<TYPE\>pegase\</TYPE\>

\<IDENTIFIER\>11260.12796\</IDENTIFIER\>

\</URI\>

\</SAMEAS\>

\</NOTICE\>

##### Retrieve the RDF/XML formatted metadata for a given resource

**Description**

This service allows the user to search for the RDF (Resource Description Framework) content of the given object. The object to search for can be a work, an expression, a manifestation, a dossier, an event, a top level event or an agent.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

The following HTTP headers may be set on the request:

− Accept:application/rdf+xml

In this case, the resulting RDF notice will contain the direct and inferred triples.

− Accept:application/rdf+xml;notice=non-inferred

In this case, the inferred triples will be excluded from the resulting RDF notice.

− Negotiate:vlist

If it is present, the response will include an Alternates header indicating all alternative representations of the returned object. Currently, this header is supported only for requests on manifestation level.

If the Accept header is not present, \* or \*/\* and the production identifier matches a WEM object, it will behave like if set to Accept:application/rdf+xml.

Here follows an example of valid request that retrieve the same RDF, using cURL:

− curl <http://publications.europa.eu/resource/cellar/b84f49cd-> 750f-11e3-8e20-01aa75ed71a1 -L

− curl <http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01 -L

− curl <http://publications.europa.eu/resource/celex/32014R0001> -L

− curl -H 'Accept: application/rdf+xml' http:// publications.europa.eu/resource/celex/32014R0001 -L

![](dc1b910738f55de9484b891a49f9fda5.png)

− curl -H 'Accept:' <http://publications.europa.eu/> resource/celex/32014R0001 -L

− curl -H 'Accept: \*' <http://publications.europa.eu/> resource/celex/32014R0001 -L

− curl -H 'Accept:\*/\*' <http://publications.europa.eu/> resource/celex/32014R0001 -L

**Response**

The response is an XML-formatted sheet containing the RDF metadata of the object.

Here follows an example of returned notice:

\<rdf:RDF [...] \>

\<rdf:Description rdf:about="[http://publications.europa.](http://publications.europa/) eu/resource/oj/JOL_2014_001_R_0001_01.ELL"\>

\<rdf:type rdf:resource="[http://publications.europa.](http://publications.europa/) eu/ontology/cdm\#expression"/\>

\</rdf:Description\>

\<rdf:Description rdf:about="[http://publications.](http://publications/) europa.eu/resource/cellar/b84f49cd-750f-11e3-8e20- 01aa75ed71a1.0022"\>

\<owl:sameAs rdf:resource="[http://publications.europa.](http://publications.europa/) eu/resource/oj/JOL_2014_001_R_0001_01.SLV"/\>

\</rdf:Description\>

\<rdf:Description rdf:about="[http://publications.europa.](http://publications.europa/) eu/resource/celex/32013R1421"\>

\<j.0:resource_legal_consolidated_by_act\_ consolidated rdf:resource="<http://publications.europa.eu/> resource/celex/02012R0978-20141001"/\>

\<j.0:consolidated_by rdf:resource="http:// publications.europa.eu/resource/celex/02012R0978-20141001"/\>

\<j.0:resource_legal_consolidated_by_act\_ consolidated rdf:resource="<http://publications.europa.eu/> resource/celex/02012R0978-20150101"/\>

\<j.0:consolidated_by rdf:resource="http:// publications.europa.eu/resource/celex/02012R0978-20150101"/\>

\</rdf:Description\> [...]

\</rdf:RDF\>

##### Retrieve the RDF/XML formatted metadata of the tree whose root is a given resource

**Description**

This service allows the user to search for the RDF (Resource Description Framework) tree whose root is the given object. The object to search for can be a work, a dossier, a top level event or an agent.

![](91bfec9f26742edb5044e7b00579d78e.png)

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

The following HTTP headers may be set on the request:

− Accept:application/rdf+xml;notice=tree

In this case, the resulting RDF notice will contain the direct and inferred triples.

− Accept:application/rdf+xml;notice=non-inferred-tree

In this case, the inferred triples will be excluded from the resulting RDF notice.

Here follows some examples of valid requests that retrieve the same RDF, using cURL :

− curl -H 'Accept:application/rdf+xml;notice=tree' http:// publications.europa.eu/resource/cellar/b84f49cd-750f-11e3- 8e20-01aa75ed71a1 -L

− curl -H 'Accept:application/rdf+xml;notice=tree' http:// publications.europa.eu/resource/oj/JOL_2014_001_R_0001_01 -L

− curl -H 'Accept:application/rdf+xml;notice=tree' http:// publications.europa.eu/resource/celex/32014R0001 -L

**Response**

The response is an XML-formatted sheet containing the RDF metadata of the tree.

Here follows an example of returned notice:

\<rdf:RDF [...] \>

\<rdf:Description rdf:about="<http://publications.europa.eu/> resource/authority/language/EST"\>

\<rdf:type rdf:resource="<http://publications.europa.eu/> ontology/cdm\#language"/\>

\<rdf:type rdf:resource="<http://www.w3.org/2004/02/skos/> core\#Concept"/\>

\<j.1:inScheme rdf:resource="[http://publications.](http://publications/) europa.eu/resource/authority/language"/\>

\<j.0:language_used_by_expression rdf:resource="http:// publications.europa.eu/resource/oj/JOL_2014_001_R_0001_01.

EST"/\>

\</rdf:Description\>

![](dc1b910738f55de9484b891a49f9fda5.png)

\<rdf:Description rdf:about="[http://publications.](http://publications/) europa.eu/resource/cellar/b84f49cd-750f-11e3-8e20- 01aa75ed71a1.0005.01"\>

\<j.2:metsStructSuperDiv rdf:resource="http:// publications.europa.eu/resource/cellar/b84f49cd-750f-11e3- 8e20-01aa75ed71a1.0005"/\>

\<j.2:lastModificationDate rdf:datatype="http:// [www.w3.org/2001/XMLSchema\#dateTime](http://www.w3.org/2001/XMLSchema#dateTime)"\>2014-01- 04T08:10:26.028+01:00\</j.2:lastModificationDate\>

\<owl:sameAs rdf:resource="[http://publications.europa.](http://publications.europa/) eu/resource/uriserv/OJ.L_.2014.001.01.0001.01.ELL.pdfa1a"/\>

\<j.0:manifestation_has_item rdf:resource="http:// publications.europa.eu/resource/cellar/b84f49cd-750f-11e3- 8e20-01aa75ed71a1.0005.01/DOC_1"/\>

[...]

\</rdf:Description\> [...]

\</rdf:RDF\>

##### Retrieve content streams

**Description**

This service allows the user to retrieve the content stream of the manifestation belonging to the given work and to the expression in the given accept language, and which contains at least 1 content stream of the given accept format.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

The following HTTP headers must be set on the request:

− Accept:{mime-type}, where {mime-type} is a valid (or a comma- separated list of) mimetype that identify the format of the content stream to return. Possible values are:

-   application/epub+zip
-   application/msword
-   application/pdf
-   application/pdf;type=pdf1x
-   application/pdf;type=pdfa1a
-   application/pdf;type=pdfa1b

![](91bfec9f26742edb5044e7b00579d78e.png)

-   application/pdf;type=pdfx
-   application/rdf+xml
-   application/sparql-query
-   application/sparql-results+xml
-   application/vnd.amazon.ebook
-   application/vnd.ms-excel
-   application/vnd.ms-powerpoint
-   application/vnd.openxmlformats-officedocument. presentationml.presentation
-   application/vnd.openxmlformats-officedocument. presentationml.slideshow
-   application/vnd.openxmlformats-officedocument. spreadsheetml.sheet
-   application/vnd.openxmlformats-officedocument. wordprocessingml.document.main+xml
-   application/x-mobipocket-ebook
-   application/xhtml+xml
-   application/xhtml+xml;type=simplified
-   application/xml
-   application/xml;type=fmx2
-   application/xml;type=fmx3
-   application/xml;type=fmx4
-   application/xslt+xml
-   application/zip
-   image/gif
-   image/jpeg
-   image/png
-   image/tiff
-   image/tiff-fx
-   text/html
-   text/html;type=simplified
-   text/plain
-   text/rtf
-   text/sgml
-   text/sgml;type=fmx2
-   text/sgml;type=fmx3

    − Accept-Language:{acc-lang}, where {acc-lang} is a 3-chars ISO_639-3 language code identifying the accept language to use: this will be used for retrieving the correct expression

    − Accept-Max-Cs-Size:{size}, where {size} is a positive integer (max. value = 263-1) which specifies the max. content stream size in bytes. If the actual content stream size is bigger than specified, a “406 - Not Acceptable” response is given.

![](dc1b910738f55de9484b891a49f9fda5.png)

Here follows some examples of valid request that retrieve the same content stream, using cURL:

− curl -H 'Accept:application/xhtml+xml' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1 -L

− curl -H 'Accept:application/xhtml+xml' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/oj/> JOL_2014_001_R_0001_01 -L

− curl -H 'Accept:application/xhtml+xml' -H 'Accept- Language:fra' –H 'Accept-Max-Cs-Size:209715200' http:// publications.europa.eu/resource/celex/32014R0001 -L

**Response**

The associated content stream.

##### Retrieve content stream collections

**Description**

This service allows the user to retrieve a collection (in zip or list format) of the content streams of the manifestation belonging to the given work and to the expression in the given accept language, and which contains at least 1 content stream of the given accept format.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/resource/>{ps-name}/{ps- id}?language={dec-lang}

where:

− {ps-name} is a valid production system name

− {ps-id} is a valid production system id identifying a work, and compatible with its {ps-name}

The following HTTP headers must be set on the request:

− Accept:{mime-type}, where {mime-type} is a valid (or a comma- separated list of) mimetype that identify the format of the content stream to return. Possible values are:

-   application/list;mtype={manifestation-type}
-   application/zip;mtype={manifestation-type}

    The mtype token carries the {manifestation-type}, which must be set to the value of cdm:manifestation_type of the desired manifestation

    − Accept-Language:{acc-lang}, where {acc-lang} is a 3-chars ISO_639-3 language code identifying the accept language to use: this will be used for retrieving the correct expression

![](91bfec9f26742edb5044e7b00579d78e.png)

Here follows some examples of valid request that retrieve the same content stream, using cURL:

− curl -H 'Accept:application/zip;mtype=fmx4' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1 -L

− curl -H 'Accept:application/list;mtype=fmx4' -H 'Accept- Language:fra' <http://publications.europa.eu/resource/> cellar/b84f49cd-750f-11e3-8e20-01aa75ed71a1 -L

**Response**

The associated content streams in the requested format:

− **zip:** a zip file containing all content stream files of the requested manifestation

− **list:** an html list containing all content stream file names of the requested manifestation

*Note:* If the given resource is a manifestation and the mtype token does not match its type, the mtype token is ignored and content streams of the given manifestation are returned.

##### NAL/Eurovoc services

We describe hereby the available services for retrieving the information related to the NAL/Eurovoc objects.

Some of the services below rely heavily on the notions of:

− concept, which is the class defined by the resource URI

[http://publications.europa.eu/ontology/cdm\#concept.](http://publications.europa.eu/ontology/cdm#concept)

It is the superclass of all concepts used in Cellar's ontology and a direct subclass of the SKOS concept ([http://www.w3.org/2004/02/skos/core\#Concept](http://www.w3.org/2004/02/skos/core#Concept)), thus it can be seen as the topmost class of Cellar's ontology

− concept scheme, which has the same meaning as the SKOS concept scheme ([http://www.w3.org/2004/02/skos/core\#ConceptScheme](http://www.w3.org/2004/02/skos/core#ConceptScheme)): an aggregation of one or more concepts.

Semantic relationships (links) between those concepts may also be viewed as part of a concept scheme. This definition is, however, meant to be suggestive rather than restrictive, and there is some flexibility in the formal data model of the Cellar.

![](dc1b910738f55de9484b891a49f9fda5.png)

##### Retrieve a NAL table

This service allows the user to retrieve the complete dump of a NAL or Eurovoc object. Cellar currently exposes two REST endpoints for the NAL. The first one can be used to retrieve a particular NAL while the second one can be used to retrieve the list of operational NAL in CELLAR:

− /nal/list which returns a list of all the NAL URIs currently operational in Cellar

− /nal/get which retrieves the NAL referenced by the NAL URI argument

1.  *REST endpoint /NAL/list*

    **Request**

    The user must fire a GET request to the following URL:

    <http://publications.europa.eu/webapi/nal/list>

    **Response**

    The response will be a comma separated list of all the NAL URIs currently in use by Cellar.

1.  *REST endpoint /nal/get*

    This endpoint allows the retrieval of the NAL in RDF format. The XML version of NAL was deprecated in previous versions of Cellar.

    **Request**

    The user must fire a GET request to the following URL:

    [http://publications.europa.eu/webapi/nal/get?nalUri=](http://publications.europa.eu/webapi/nal/get?nalUri){nalUri}

    where {nalUri} is a NAL URI that can be retrieved from REST endpoint /nal/ list (see previous section).

    **Response**

    The response content will be of type application/rdf+xml returned as an XML-formatted SKOS/RDF.

    Here follow some valid examples of request:

    − [http://publications.europa.eu/webapi/nal/get?nalUri=http://](http://publications.europa.eu/webapi/nal/get?nalUri=http%3A//) publications.europa.eu/resource/authority/file-type

    − [http://publications.europa.eu/webapi/nal/get?nalUri=http://](http://publications.europa.eu/webapi/nal/get?nalUri=http%3A//) eurovoc.europa.eu/100141

![](91bfec9f26742edb5044e7b00579d78e.png)

##### Retrieve the supported languages

**Description**

This service allows the user to retrieve the supported languages of the system. Also, the user may ask for the supported languages of a particular NAL/Eurovoc concept scheme.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/>{type}/ getSupportedLanguages?concept_scheme={cs-uri}

where:

− {type} can be either nal or eurovoc, depending on whether the user wants to retrieve the supported languages for NAL or Eurovoc objects, respectively

− {cs-uri} is the resource URI of the NAL/Eurovoc concept scheme.

This parameter is not mandatory: if not specified, all supported languages of the system will be retrieved.

Here follows some examples of valid requests:

− <http://publications.europa.eu/webapi/nal/> getSupportedLanguages

− <http://publications.europa.eu/webapi/nal/> getSupportedLanguages?concept_scheme=http%3A%2F%2Fpubl ications.europa.eu%2Fresource%2Fauthority%2Fcountry

− <http://publications.europa.eu/webapi/eurovoc/> getSupportedLanguages

**Response**

The list of supported languages in JSON format. For more information about JSON format, please see Annexe 3.

Example:

[

{

"code": "mlt"

},

{

"code": "deu"

},

[...other languages]

]

![](dc1b910738f55de9484b891a49f9fda5.png)

##### Retrieve a concept scheme

**Description**

This service allows the user to retrieve a NAL or Eurovoc concept scheme.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/>{type}/ getConceptScheme?concept_Scheme={cs-uri}

where

− {type} can be either nal or eurovoc, depending on whether the user wants to retrieve a NAL or an Eurovoc concept scheme, respectively

− {cs-uri} is the resource URI of the NAL/Eurovoc concept scheme.

This parameter is mandatory only for NALs (that is, when {type} is nal): if not specified for Eurovocs ({type} is eurovoc), it defaults to [http://eurovoc.europa.eu/100141.](http://eurovoc.europa.eu/100141)

Here follows some examples of valid requests:

− <http://publications.europa.eu/webapi/nal/> getConceptScheme?concept_scheme=http%3A%2F%2Fpublications. europa.eu%2Fresource%2Fauthority%2Fcountry

− <http://publications.europa.eu/webapi/eurovoc/> getConceptScheme?concept_scheme=http%3A%2F%2Feurovoc. europa.eu%2F100225

− <http://publications.europa.eu/webapi/eurovoc/getConceptScheme>

**Response**

The concept scheme in JSON format. Example:

{

"date": null, "lastModified": null, "version": null, "uri": {

"uri": "<http://eurovoc.europa.eu/100225>"

},

"labels": [

{

"language": "ron",

"string": "3611 tiin e umaniste"

},

{

"language": "hun",

"string": "3611 humán tudományok"

},

[...other labels]

]

}

![](91bfec9f26742edb5044e7b00579d78e.png)

##### Retrieve the concept schemes

**Description**

This service allows the user to retrieve all the concept schemes of NALs or Eurovocs.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/>{type}/getConceptSchemes

where {type} can be either nal or eurovoc, depending on whether the user wants to retrieve the concept schemes of NALs or Eurovocs, respectively.

Here follows some examples of valid requests:

− <http://publications.europa.eu/webapi/nal/getConceptSchemes>

− <http://publications.europa.eu/webapi/eurovoc/getConceptSchemes>

**Response**

The list of concept schemes in JSON format. Example:

[

{

"date": null, "lastModified": null, "version": null, "uri": {

"uri": "<http://eurovoc.europa.eu/100225>"

},

"labels": [

{

"language": "ron",

"string": "3611 tiin e umaniste"

},

{

"language": "hun",

"string": "3611 humán tudományok"

},

[...other labels]

]

},

{

"date": null, "lastModified": null, "version": null, "uri": {

"uri": "<http://eurovoc.europa.eu/100226>"

},

"labels": [

![](dc1b910738f55de9484b891a49f9fda5.png)

{

"language": "ron",

"string": "4006 organizarea afacerilor"

},

{

"language": "hun",

"string": "4006 gazdasági szervezetek" },

[...other labels]

]

},

[...other concepts schemes]

]

##### Retrieve a concept

**Description**

This service allows the user to retrieve the translation of a given concept into a specified language.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/>{type}/ getConcept?concept_uri={con-uri}&language={lang}

where:

− {type} can be either nal or eurovoc, depending on whether the user wants to retrieve the translation of a NAL or Eurovoc concept, respectively

− {con-uri} is the resource URI of the NAL/Eurovoc concept

− {lang} is a 3-chars ISO_639-3 language code identifying the language the user wants to translate the concept with.

Here follows some examples of valid requests:

− [http://publications.europa.eu/webapi/nal/getConcept?concept\_](http://publications.europa.eu/webapi/nal/getConcept?concept_) uri=http%3A%2F%2Fpublications.europa.eu%2Fresource%2Fauthorit y%2Fcountry/ELL&language=eng

− <http://publications.europa.eu/webapi/eurovoc/> getConcept?concept_uri=http%3A%2F%2Feurovoc.europa. eu%2F3928&language=fra

**Response**

The translated concept in JSON format. Example:

[

{

"language": "fra", "identifier": "3928", "notations": [

![](91bfec9f26742edb5044e7b00579d78e.png)

],

"uri": {

"uri": "<http://eurovoc.europa.eu/3928>"

},

"prefLabel": { "language": "fra",

"string": "sciences du comportement"

},

"altLabels": [

"psychologie du comportement", "behaviorisme"

],

"hiddenLabels": [

"comportement, psychologie du", "comportement, sciences du"

]

}

]

##### Retrieve the concept relatives

**Description**

This service allows the user to retrieve the list of concepts having a specific semantic relation with the given concept.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/>{type}/ getConceptRelatives?concept_uri={con-uri}&relation_uri={rel- uri}&language={lang}

where:

− {type} can be either nal or eurovoc, depending on whether the user wants to retrieve the concept relatives of a NAL or Eurovoc concept, respectively

− {con-uri} is the resource URI of the NAL/Eurovoc concept of which retrieving the concept relatives

− {rel-uri} is the resource URI of the SKOS relation scheme to use, namely:

-   [http://www.w3.org/2004/02/skos/core\#broader](http://www.w3.org/2004/02/skos/core#broader): to use in order to retrieve the concepts that are more general in meaning than the given concept. Broader concepts are typically rendered as parents in a concept hierarchy
-   [http://www.w3.org/2004/02/skos/core\#narrower](http://www.w3.org/2004/02/skos/core#narrower): to use in order to retrieve the concepts that are more specific in meaning than the given concept. Narrower concepts are typically rendered as children in a concept hierarchy

![](dc1b910738f55de9484b891a49f9fda5.png)

-   [http://www.w3.org/2004/02/skos/core\#related](http://www.w3.org/2004/02/skos/core#related): to use in order to retrieve the concepts that have an associative semantic relationship with the given concept

    − {lang} is a 3-chars ISO_639-3 language code identifying the language the user wants to retrieve the concept relatives with.

    Here follows some examples of valid requests:

    − <http://publications.europa.eu/webapi/nal/> getConceptRelatives?concept_uri=http%3A%2F%2Fpublications. europa.eu%2Fresource%2Fauthority%2Fcountry/ANT&relation\_ uri=http%3A%2F%2Fwww.w3.org%2F2004%2F02%2Fskos%2Fcore%23br oader&language=eng

    − <http://publications.europa.eu/webapi/eurovoc/> getConceptRelatives?concept_uri=http%3A%2F%2Feurovoc. europa.eu%2F3928&relation_uri=http%3A%2F%2Fwww.w3.org%2F20 04%2F02%2Fskos%2Fcore%23narrower&language=fra

    **Response**

    The list of concepts that have a semantic relation with the given concept, in JSON format.

    Example:

    [

    {

    "language": "fra", "identifier": "3928", "notations": [

    ],

    "uri": {

    "uri": "<http://eurovoc.europa.eu/3928>"

    },

    "prefLabel": { "language": "fra",

    "string": "sciences du comportement"

    },

    "altLabels": [

    "psychologie du comportement", "behaviorisme"

    ],

    "hiddenLabels": [

    "comportement, psychologie du", "comportement, sciences du"

    ]

    },

    {

    "language": "fra", "identifier": "3956",

![](91bfec9f26742edb5044e7b00579d78e.png)

"notations": [

],

"uri": {

"uri": "<http://eurovoc.europa.eu/3956>"

},

"prefLabel": { "language": "fra",

"string": "sciences sociales"

},

"altLabels": [ "sciences humaines"

],

"hiddenLabels": [ "sociales, sciences", "humaines, sciences"

]

},

[...other concepts]

]

##### Retrieve the top concepts

**Description**

This service allows the user to retrieve the top concepts of a given concept scheme in a specified language.

A top concept is a concept that is topmost in the broader/narrower concept hierarchies for a given concept scheme, providing an entry point to these hierarchies.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/>{type}/ getTopConcepts?concept_scheme={cs-uri}&language={lang}

where:

− {type} can be either nal or eurovoc, depending on whether the user wants to retrieve the top concepts of a NAL or Eurovoc concept, respectively

− {cs-uri} is the resource URI of the NAL/Eurovoc concept scheme of which retrieving the top concepts

− {lang} is a 3-chars ISO_639-3 language code identifying the language the user wants to retrieve the top concepts with.

Here follows some examples of valid requests:

− <http://publications.europa.eu/webapi/nal/> getTopConcepts?concept_scheme=http%3A%2F%2Fpublication s.europa.eu%2Fresource%2Fauthority%2Fcountry&language=eng

− <http://publications.europa.eu/webapi/eurovoc/> getTopConcepts?concept_scheme=http%3A%2F%2Feurovoc. europa.eu%2F100225&language=fra

![](dc1b910738f55de9484b891a49f9fda5.png)

**Response**

The list of top concepts in JSON format. Example:

[

{

"language": "fra", "identifier": "3928", "notations": [

],

"uri": {

"uri": "<http://eurovoc.europa.eu/3928>"

},

"prefLabel": { "language": "fra",

"string": "sciences du comportement"

},

"altLabels": [

"psychologie du comportement", "behaviorisme"

],

"hiddenLabels": [

"comportement, psychologie du", "comportement, sciences du"

]

},

{

"language": "fra", "identifier": "3956", "notations": [

],

"uri": {

"uri": "<http://eurovoc.europa.eu/3956>"

},

"prefLabel": { "language": "fra",

"string": "sciences sociales"

},

"altLabels": [ "sciences humaines"

],

"hiddenLabels": [ "sociales, sciences", "humaines, sciences"

]

},

[...other concepts]

]

![](91bfec9f26742edb5044e7b00579d78e.png)

##### Retrieve the domains

**Description**

This service allows the user to retrieve the domains facets of the Eurovoc thesaurus.

**Request**

The user must fire a GET request to the following URL:

<http://publications.europa.eu/webapi/eurovoc/getDomains>

**Response**

The list of domains in JSON format. Example:

[

{

"identifier": "28", "uri": {

"uri": "<http://eurovoc.europa.eu/100149>"

},

"conceptSchemes": [

{

"uri": "<http://eurovoc.europa.eu/100212>"

},

{

"uri": "<http://eurovoc.europa.eu/100213>"

},

[...other concept scheme URIs]

],

"labels": [

{

"language": "ron",

"string": "28 PROBLEME SOCIALE"

},

{

"language": "hun",

"string": "28 TÁRSADALMI KÉRDÉSEK"

},

[...other labels]

]

},

{

"identifier": "24", "uri": {

"uri": "<http://eurovoc.europa.eu/100148>"

},

"conceptSchemes": [

{

"uri": "<http://eurovoc.europa.eu/100200>"

},

![](dc1b910738f55de9484b891a49f9fda5.png)

{

"uri": "<http://eurovoc.europa.eu/100203>"

},

[...other concept scheme URIs]

],

"labels": [

{

"language": "hr", "string": "24 FINANCIJE"

},

{

"language": "ron", "string": "24 FINANTE"

},

[...other labels]

]

},

[...other domains]

]

##### Notifications: RSS and Atom feeds

This notification service provides information about the ingesting of documents, the loading of NALs and the loading of ontologies in the form of an RSS or Atom feed. By accessing these feeds, it is possible to get a complete history of the performed actions.

##### Request

To specify if the response is given in RSS or in Atom format, the HTTP header Accept:{accept-type} must be specified, where {accept-type} is a string which may assume the following values:

− application/rss+xml, in which case the Cellar will provide the results as an RSS feed

− application/atom+xml, in which case the Cellar will provide the results as an ATOM feed

If this header is not set, it defaults to application/rss+xml. To request a feed, the following URL must be used:

http://[CELLAR_IP]:[CELLAR_PORT]/[CELLAR_CONTEXT]/webapi/ notification/{channel}?{parameters}

The channels supported by the public feed are: ingestion, nal, sparql-load and ontology. The next chapters describe the different notification types and their possible parameters.

![](91bfec9f26742edb5044e7b00579d78e.png)

1.  *Ingestion feed*

    Provides an overview of all ingestion actions, filtered by the given parameters.

    − **startDate:** Defines the date (inclusive) since which the ingestion notifications shall be retrieved. Its format must match one of the following:

    -   yyyy-MM-dd (2013-12-02)
        -   yyyy-MM-dd'T'HH:mm:ss (2013-12-02T09:24:22)
            -   yyyy-MM-dd'T'HH:mm:ssZZ (2013-12-02T09:24:22-01:00)
                -   yyyy-MM-dd'T'HH:mm:ss.SSSZZ (2013-12-02T09:24:22.123-01:00).

                    − **endDate:** Defines the date (inclusive) until which the ingestion notifications shall be retrieved. It has the same format of startDate

                    − **type:** A string value, either CREATE, UPDATE or DELETE. It defines the type of ingestion to be retrieved

                    − **wemiClasses:** A comma-separated list of WEMI classes: work, expression, manifestation, item, dossier, event or agent

                    − **page:** The number of the page on the feed to display, should the total number of entries returned be higher than 1000 (defined in property cellar. service.notification.itemsPerPage). This parameter may be used to page large results by firing subsequent requests and setting incremental values on this parameter. If not set, page 1 is returned.

                    *Note:* only the startDate parameter is mandatory; if an optional parameter is not set, no filter is applied.

                1.  *NAL feed*

                    Provides an overview of all NAL loading actions, filtered by the given parameters.

                    − **startDate, endDate, page:** same as explained above.

                2.  *Sparql-load feed*

                    Provides an overview of all SPARQL loading actions, filtered by the given parameters.

                    − **startDate, endDate, page:** same as explained above.

                3.  *Ontology feed*

                    Provides an overview of all ontology loading actions, filtered by the given parameters.

                    − **startDate, endDate, page:** same as explained above.

                4.  *Example requests*

                    Retrieve: the 3rd page of the RSS feed containing the updates of works and events occurred from the 1st July to the 31st July 2016:

                    − curl -H 'Accept:application/rss+xml' "http:// publications.europa.eu/webapi/notification/ ingestion?startDate=2016-07-01&endDate=2016-07-31&type=UP DATE&wemiClasses=work,event&page=3"

                    Retrieve the 1st page of the ATOM feed containing the creations, updates and deletions of all types of entities occurred from the 1st July 2016 until now:

![](dc1b910738f55de9484b891a49f9fda5.png)

− curl -H 'Accept:application/atom+xml' "http:// publications.europa.eu/webapi/notification/ ingestion?startDate=2016-07-01"

Retrieve the 3rd page of the RSS feed containing the successful NAL updates occurred from the 1st July to the 31st July 2016:

− curl -H 'Accept:application/rss+xml' http:// publications.europa.eu/webapi/notification/ nal?startDate=2016-07-01&endDate=2016-07-31&page=3

Retrieve the 3rd page of the RSS feed containing the successful sparql-load updates occurred from the 1st January 2023 to the 31st July 2023:

− curl -H 'Accept:application/rss+xml' http:// publications.europa.eu/webapi/notification/

sparql-load?startDate=2023-01-01&endDate=2023-07-31&page=3

Retrieve the 1st page of the ATOM feed containing the successful ontology updates occurred from the 1st July 2016 until now:

− curl -H 'Accept:application/atom+xml' http:// publications.europa.eu/webapi/notification/ ontology?startDate=2016-07-01

##### Response

The response contains the following common information (no matter what format or feed).

− **title:** The descriptive title of the feed.

− **startDate:** It contains the value of the as startDate parameter.

− **endDate:** It contains the value of the endDate parameter; it defaults to current date in case it is not provided, or set in the future.

− **page:** Cardinal number of the current page of the results.

− **moreEntries:** If true, the result has been paged and more entries that satisfy the request have been found. Subsequent requests should be fired with increasing page numbers.

The items (RSS) / entries (Atom) of the feed answer differ for each feed type. They are described below.

1.  *Ingestion items*

    − **guid (only for rss entries):** The unique id identifying the ingestion event.

    − **notifEntry:id:** Same as above.

    − **notifEntry:cellarId:** The cellar ID of the ingested element.

    − **notifEntry:rootCellarId:** The cellar ID of the root element of the WEMI hierarchy containing the ingested element.

    − **notifEntry:type:** The type of the ingestion action (create, update or delete).

![](91bfec9f26742edb5044e7b00579d78e.png)

− **notifEntry:priority:** The priority of the ingestion event (AUTHENTICOJ, DAILY or BULK).

− **notifEntry:wemiClass:** The WEMI class (work, expression, manifestation, item, dossier, event, top level event or agent) of the ingested element.

− **notifEntry:classes:** The class hierarchy of the ingested element: the top class is the most specific, the bottom one the most general.

− **notifEntry:rootIdentifiers:** The WEMI root (work, dossier, top level event or agent) identifiers of the ingested element.

− **notifEntry:identifiers:** The sameases of the ingested element.

− **notifEntry:date:** The ingestion date and time.

1.  *NAL items*

    − **guid (only for rss entries):** The URI of the loaded NAL.

    − **version:** The version (creation date) of the NAL.

    − **date:** The date and time of the NAL loading.

    1.  *Sparql-load items*

        − **guid (only for rss entries):** The URI of the loaded graph.

        − **date:** The date and time of the SPARQL loading.

        1.  *Ontology items*

            − **guid (only for rss entries):** The URI of the loaded ontology.

            − **version:** The version of the loaded ontology.

            − **date:** The date and time of the ontology loading.

            1.  *Example response (RSS ingestion)*

                \<rss version="2.0" xmlns:notifReq="<http://publications.europa.eu/rss/>

                notificationRequest"\> xmlns:notifEntry="<http://publications.europa.eu/rss/>

                notificationEntry"\>

                \<channel\>

                \<title\>Ingestion Notification Messages Response\</title\>

                \<notifReq:startDate\>2012-01-01T00:00:00+01:00\</ notifReq:startDate\>

                \<notifReq:endDate\>2012-12-31T00:00:00+01:00\</ notifReq:endDate\>

                \<notifReq:page\>1\</notifReq:page\>

                \<notifReq:moreEntries\>false\</notifReq:moreEntries\>

                \<item\>

                \<guid isPermaLink="false"\>7081775\</guid\>

                \<notifEntry:id\>7081775\</notifEntry:id\>

                \<notifEntry:cellarId\>cellar:ca753ae9-

                cf80-11e2-**859e-01aa75ed71a1\</notifEntry:cellarId\>**

![](dc1b910738f55de9484b891a49f9fda5.png)

\<notifEntry:rootCellarId\>cellar:ca753ae9-cf80-11e2- 859e-01aa75ed71a1\</notifEntry:rootCellarId\>

\<notifEntry:type\>update\</notifEntry:type\>

\<notifEntry:priority\>DAILY\</notifEntry:priority\>

\<notifEntry:classes\>

\<notifEntry:class\><http://publications.europa.eu/> ontology/cdm\#case-law_national\</notifEntry:class\>

\<notifEntry:class\><http://publications.europa.eu/> ontology/cdm\#case-law\</notifEntry:class\>

\<notifEntry:class\><http://publications.europa.eu/> ontology/cdm\#resource_legal\</notifEntry:class\>

\<notifEntry:class\><http://publications.europa.eu/> ontology/cdm\#work\</notifEntry:class\>

\</notifEntry:classes\>

\<notifEntry:identifiers\>

\<notifEntry:identifier\>oj:JOL_2012_154

\_R_0012_01\</notifEntry:identifier\>

\<notifEntry:identifier\>celex:32006D0241\</ notifEntry:identifier\>

\</notifEntry:identifiers\>

\<notifEntry:date\>2012-06-11T09:13:58+01:00\</ notifEntry:date\>

\</item\>

\</channel\>

\</rss\>

![](91bfec9f26742edb5044e7b00579d78e.png)

## Master data

### Ontology: CDM

The Cellar’s ontology is called Common Data Model or CDM. It is based on the model of Functional Requirements for Bibliographical Records (FRBR) published by the International Federation of Library Associations (22). Basic definitions of FRBR are:

**Work:** a distinct intellectual or artistic creation.

**Expression:** the realisation of a work in the form of alphanumeric, musical or choreographic notation, sound, image, object, movement, etc.

**Manifestation:** the physical embodiment of an expression of a work.

**Item:** a single exemplar of a manifestation.

**Agent:** the responsible for an intellectual or artistic content.

**Dossier:** the entity that serves as the subject of intellectual or artistic endeavor.

**Event:** an action or an occurrence.

Expressions are linguistic versions in the Cellar. Please note that some documents, like some maps or posters from the EU Bookshop, may have more than one language. All languages used come from the corresponding authority table (see section 6.2).

Manifestations in the Cellar are the file types: for example, PDF or Formex. All formats come from the corresponding authority table (see section 6.2). There are even ‘print’ manifestations, which have no associated content, just metadata, to express that the OP keeps a printed version of that expression (language) and work.

Finally, items are the digital files. There may be more than one, like the OJs with many pages such as the EU budget, which is split into several files. Also metadata is stored in items (files), in RDF format.

The full list of CDM properties is expressed in OWL with RDF format (see section 2.3) and can be consulted on the Metadata Registry (MDR) page ([https://op.europa.eu/](https://op.europa.eu/en/web/eu-vocabularies/cdm) [en/web/eu-vocabularies/cdm](https://op.europa.eu/en/web/eu-vocabularies/cdm)).

The page contains a link towards the documentation of the CDM. In Figure 10, a screen capture of the CDM documentation is shown.

1.  <https://www.ifla.org/publications/functional-requirements-for-bibliographic-records>

![](dc1b910738f55de9484b891a49f9fda5.png)

**Figure 10: Screen capture of the CDM internal wiki**

![The documentation page introduces what is the Common Data Model and includes a description of the Common Data Model structure.](bbdc32414a26b6c9b44cfa33b3800224.jpeg)

### Authority tables, Eurovoc

In order to harmonise and standardise the codes and the associated labels used in the Publications Office, a number of named authority lists (NALs) have been defined. These NALs are also known as controlled vocabularies or value lists.

Many metadata in the Cellar are standardised with these NALs, which can be found on the MDR website (<http://publications.europa.eu/mdr/authority/>) in several formats, including SKOS.

Eurovoc is a multilingual, multidisciplinary thesaurus covering the activities of the EU, the European Parliament in particular. Currently, it contains terms in 23 EU languages (Bulgarian, Spanish, Czech, Danish, German, Estonian, Greek,

English, French, Croatian, Italian, Latvian, Lithuanian, Hungarian, Maltese, Dutch, Polish, Portuguese, Romanian, Slovak, Slovenian, Finnish and Swedish), plus Serbian.

Eurovoc can also be downloaded to be reused from the MDR website (<http://publications.europa.eu/mdr/eurovoc/>), and it has its own website (<http://eurovoc.europa.eu/>).

![](91bfec9f26742edb5044e7b00579d78e.png)

### Instance data: OJ example

Until 1 October 2023, the Official Journal of the European Union (the OJ) in which EU legal acts are published as a collation of acts with a table of contents, has at least four related works:

-   The full version, with an identifier like oj:JOA_1952_001_R
    -   Since 1 July 2013, the electronic signature of the OJ, with an identifier like oj:JOL_2014_001_R_SIG
        -   The table of contents or TOC, with an identifier like oj:JOA_195_001_R_TOC
        -   The version act by act, with at least one identifier like oj:JOA_1952_001_R_0003_01

            Please note that the identifiers are given as examples; there is no mandatory naming convention to be followed, and therefore any identifier may have any random name. In order to find the signature, TOC and acts belonging to an OJ, you should either consult them in EUR-Lex, or use the CDM properties as shown in use case 4.2.1.

            As of 1 October 2023, the Official Journal will no longer be published as a collation of acts but individually as an authentic Official Journal in PDF format.

            It will consist of:

        -   A set of acts related to a unique publication date, where an act has an identifier like

            oj:JOA_2022_001_R_0003_01

        -   For each act, the electronic signature, with an identifier like oj:JOL_2022_001_R_SIG

            Please note that the identifiers are given as examples; there is no mandatory naming convention to be followed, and therefore any identifier may have any random name. In order to find the acts and signatures belonging to an OJ Act by Act, you should either consult them in EUR-Lex, or use the CDM properties as shown in use case 4.2.2.

### Formex

Formex describes a file format created by the Publications Office for the exchange of data with its contractors. In particular, it defines the logical markup for documents which are published in the different series of the *Official Journal of the European Union*.

Since Formex v4 is based on XML, it can be reused. Some collections have manifestations in Formex, some examples are shown in chapter 5: look for URIs ending in .fmx4.

All the inf[ormation about Formex, its schema](http://formex.publications.europa.eu/) and examples can be found on the website ([http://formex.publications.europa.eu).](http://formex.publications.europa.eu/)

![](17da067af4c85585c9b967efff145ae2.png)

# PART III: Annexes

### ANNEX I — Acronyms

**CDM** common data model

**Cellar** common data repository for the Publications Office

**CJ** Court of Justice of the European Union

**CURIE** compact URI

**cURL** client URL request library **ECLI**  European case-law identifier **EU**  European Union

**FRBR** functional requirements for bibliographical records

**FTP** file transfer protocol

**HTML** hypertext markup language

**HTTP** hypertext transfer protocol

**ISO** International Organisation for Standardisation

**JSON** JavaScript object notation

**MDR** MetaData Registry

**NAL** named authority list

**OJ** *Official Journal of the European Union*

**OP** Publications Office of the European Union

**OWL** ontology web language

**PDF** portable document format

**RDF** resource description framework

**RDFS** resource description framework schema

**RESTful** representational state transfer set of web services

**RSS** rich (or RDF) site summary

**SFTP** secure file transfer protocol

**SKOS** simple knowlegde organisation system

**SPARQL** (recursive) SPARQL protocol and RDF query language

**SQL** structured query language

**TB** terabyte, worth 1024 gigabytes or 1024\*1024 megabytes

**TOC** table of contents

**URI** uniform resource identifier

**URL** uniform resource locator

**UUID** Universally Unique Identifier: identifier standard used in software construction, standardized by the Open Software Foundation (OSF)

**W3C** World Wide Web Consortium

**WEMI** Work, Expression, Manifestation and Item

**XML** extended markup language

![](917262475a724b2c157d867c2eacff0e.png)

### ANNEX II — List of tables

[**Table 1:** Examples of triples 12](#_bookmark9)

[**Table 2:** Example of an RDF file with some of the triples from Table 1 13](#_bookmark10)

[**Table 3:** Differences between relational and semantic databases 14](#_bookmark11)

[**Table 4:** Access possibilities to Cellar notifications, content and metadata 15](#_bookmark13)

[**Table 5:** EUR-Lex OJ L Complete Edition RSS extract 16](#_bookmark15)

[**Table 6:** Commented SPARQL query to get the list of countries in English,](#_bookmark20)

[with the EU laws related to them 19](#_bookmark20)

[**Table 7:** Some results of the SPARQL query in Table 6 20](#_bookmark22)

[**Table 8:** Commented SPARQL query to get the list of countries in English,](#_bookmark22)

[with the EU laws related to them 20](#_bookmark22)

[**Table 9:** Results of the SPARQL query in Table 8 showing a list of African](#_bookmark23) [countries with the number of EU laws related to them 21](#_bookmark23)

[**Table 10:** SPARQL query for getting the URIs of TOC, acts and signature](#_bookmark24)

[of an Official Journal 22](#_bookmark24)

[**Table 11:** Results of SPARQL query of Table 10, with the URIs of TOC, acts and](#_bookmark24) [signature of the Official Journal \<](#_bookmark24)<http://publications.europa.eu/> [resource/oj/JOL_2017_001_R\> 22](#_bookmark24)

[**Table 12:** SPARQL query for getting the URIs of acts and signatures](#_bookmark26)

[for a specific date of publication 23](#_bookmark26)

[**Table 13:** Part of the Results of SPARQL query of Table 12, with the URIs](#_bookmark26)

[of acts and their signatures for the publication date "2021-01-25" 23](#_bookmark26)

[**Table 14:** Example of an RSS extraction of a work 25](#_bookmark28)

[**Table 15:** Example of a branch notice extraction 25](#_bookmark28)

[**Table 16:** SPARQL query to get case-law in English, with class and ECLI 26](#_bookmark29)

[**Table 17:** SPARQL query to get all EU treaties 27](#_bookmark31)

[**Table 18:** SPARQL query to get all EU legislation in force about climate change 27](#_bookmark31)

[**Table 19:** Identifier’s conventions for production system name cellar 35](#_bookmark41)

[**Table 20:** Identifier’s conventions for production system names other than Cellar 35](#_bookmark41)

[**Table 21:** Supported European languages with their ISO_639-3 codes 78](#_bookmark51)

![](17da067af4c85585c9b967efff145ae2.png)

**ANNEX III — List of figures**

[**Figure 1:** Semantic web technologies stack 8](#_bookmark3)

[**Figure 2:** Screen capture with a configuration example](#_bookmark7)

[of the modify headers plugin for Mozilla Firefox 11](#_bookmark7)

[**Figure 3:** Cellar architecture with detail in interfaces 15](#_bookmark13)

[**Figure 4:** Cellar SPARQL endpoint 18](#_bookmark18)

[**Figure 5:** OP Portal linked data query wizard 18](#_bookmark18)

[**Figure 6:** SPARQL endpoint with the query from Table 6](#_bookmark20)

[copied and ready to be run 19](#_bookmark20)

[**Figure 7:** Map with the results from Table 9 21](#_bookmark23)

[**Figure 8:** The work-expression-manifestation-content stream hierarchy 30](#_bookmark36)

[**Figure 9:** The dossier-event hierarchy 31](#_bookmark37)

[**Figure 10:** Screen capture of the CDM internal wiki 73](#_bookmark47)

![](917262475a724b2c157d867c2eacff0e.png)

### ANNEX IV — List of ISO_639-3 codes of supported European languages

The Cellar supports the European languages identified by the following ISO_639- 3 codes:

**Table 21: Supported European languages with their ISO_639-3 codes**

| **ISO_639-3 code** | **Language**                  |
|--------------------|-------------------------------|
| **bul**            | Bulgarian                     |
| **ces**            | Czech                         |
| **dan**            | Danish                        |
| **deu**            | German                        |
| **ell**            | Modern Greek                  |
| **eng**            | English                       |
| **est**            | Estonian                      |
| **fin**            | Finnish                       |
| **fra**            | French                        |
| **gle**            | Irish                         |
| **hrv**            | Croatian                      |
| **hun**            | Hungarian                     |
| **isl**            | Icelandic                     |
| **ita**            | Italian                       |
| **lav**            | Latvian                       |
| **lit**            | Lithuanian                    |
| **mlt**            | Maltese                       |
| **nld**            | Dutch                         |
| **nor**            | Norwegian                     |
| **pol**            | Polish                        |
| **por**            | Portuguese                    |
| **ron**            | Romanian, Moldavian, Moldovan |
| **slk**            | Slovak                        |
| **slv**            | Slovene                       |
| **spa**            | Spanish, Castillian           |
| **swe**            | Swedish                       |

![](17da067af4c85585c9b967efff145ae2.png)

### ANNEX V — cURL

cURL (Client URL Request Library) is a computer software providing command- line tool for transferring data using various protocols, the most important of which, for our purposes, is HTTP/HTTPS.

The present document uses cURL for depicting all the examples of HTTP requests: cURL is preferable to in-browser or other graphical tools, as:

1.  it is independent from the OS
2.  the way a browser allows the user to build the HTTP requests may differ from browser to browser
3.  its syntax does not depend on the version used, while the browser may change during time the way it represents the HTTP request
4.  its syntax is simple and direct to the goal.

    Basic use of cURL involves simply typing curl at the command line, followed by the URL of the output to retrieve. For example, to retrieve the example.com homepage, type:

    curl [http://www.example.com](http://www.example.com/)

    For specifying an HTTP request header it is enough to type:

    curl –H 'myHeaderName:myHeaderValue' [http://www.example.com](http://www.example.com/)

    where myHeaderName is the name of the header and myHeaderValue is its value.

    This is enough for our purposes: for more information, please refer to cURL home page at [http://curl.haxx.se/.](http://curl.haxx.se/)

![](917262475a724b2c157d867c2eacff0e.png)

### ANNEX VI — JSON

JSON (JavaScript Object Notation) is a lightweight data-interchange format. It has several advantages:

1.  it is easy for humans to read and write
    1.  it is easy for machines to parse and generate
    2.  it is based on a subset of the JavaScript Programming Language, used worldwide
    3.  it is a text format that is completely language independent, but uses conventions that are familiar to programmers of the C-family of languages, including C, C++, C\#, Java, JavaScript, Perl, Python, and many others.

        These properties make JSON an ideal data-interchange language. JSON's basic types are:

        − **Number** (double precision floating-point format in JavaScript, generally depends on implementation)

        − **String** (double-quoted Unicode, with backslash escaping)

        − **Boolean** (true or false)

        − **Array** (an ordered sequence of values, comma-separated and enclosed in square brackets; the values do not need to be of the same type)

        − **Object** (an unordered collection of key:value pairs with the ':' character separating the key and the value, comma-separated and enclosed in curly braces; the keys must be strings and should be distinct from each other)

        − **null** (empty)

        Non-significant white space may be added freely around the "structural characters" (i.e. the brackets "[{]}", colon ":" and comma ",").

        The following example shows the JSON representation of an object that describes a person. The object has string fields for first name and last name, a number field for age, contains an object representing the person's address, and contains a list (an array) of phone number objects.

        {

        "firstName": "John",

        "lastName": "Smith", "age": 25,

        "address": {

        "streetAddress": "21 2nd Street", "city": "New York",

        "state": "NY", "postalCode": "10021"

        },

        "phoneNumber": [

        {

        "type": "home", "number": "212 555-1234"

        },

        {

        "type": "fax", "number": "646 555-4567"

        }

        ]

        }

![](17da067af4c85585c9b967efff145ae2.png)

### ANNEX VII — OWL

The Common Data Model is expressed formally as an ontology – a set of concepts within a domain, and the relationships among those concepts – according to a format called the Web Ontology Language (OWL). The ontology formally defines the various classes and properties and assigns unique URIs to them that reside under the URI:

[http://op.europa.eu/en/web/eu-vocabularies/cdm](https://op.europa.eu/en/web/eu-vocabularies/cdm)

The ontology also defines certain inferred behaviours for classes and properties. For example, being a member of a subclass, e.g. a directive, implies being a member also of its superclasses, e.g. secondary legislation and resource legal. Also, if act A repeals another act B it is possible to infer that B is repealed by A. Inferred classes and properties are also exposed by the Cellar alongside explicitly provided ones.

### ANNEX VIII — Citation and licence

If you need to cite any document present in the Cellar, we recommend that you follow the rules from the Interinstitutional style guide (<http://publications.europa.eu/code/en/en-250900.htm>).

Cellar content can be used in accordance with the conditions laid out in

\<[https://publications.europa.eu/en/web/about-us/legal-notices/eu-law-and-](https://publications.europa.eu/en/web/about-us/legal-notices/eu-law-and-publications-website#copyright) [publications-website\#copyright](https://publications.europa.eu/en/web/about-us/legal-notices/eu-law-and-publications-website#copyright)\>. As to the *Who is who* dataset, please check specific rules in \<[http://europa.eu/whoiswho/public/index.cfm?fuseaction=idea.](http://europa.eu/whoiswho/public/index.cfm?fuseaction=idea.show_page&pagename=legal_notice) [show_page&pagename=legal_notice](http://europa.eu/whoiswho/public/index.cfm?fuseaction=idea.show_page&pagename=legal_notice)\>.

![](f83d3cf60796efc67da8d4cf882b049c.png)

![](d024d7cec19291be39108c53c926a1b7.png)Publications Office

of the European Union
