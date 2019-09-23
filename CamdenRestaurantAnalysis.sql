--create database Camden
--go

use Camden
go

if OBJECT_ID('dbo.BusinessTypes') is not null
begin
	drop table dbo.BusinessTypes
end
go

select distinct
	 [Business Type ID]
	,[Business Type Description]
into dbo.BusinessTypes
from dbo.Businesses

USE [Camden]
GO

if OBJECT_ID('dbo.CleansedBusinesses') is not null
begin
	drop table dbo.CleansedBusinesses
end
go

set dateformat dmy
SELECT [Business Name] as Business
      ,[Address Line 1] as Address1
      ,[Address Line 2] as Address2
      ,[Address Line 3] as City
      ,[Postcode]
      ,[Food Hygiene Rating Scheme ID] as SchemeID
      ,[Food Hygiene Rating Scheme Type] as SchemeType
      ,try_cast([Hygiene Score] as int) as HygieneScore
      ,try_cast([Structural Score] as int) as StructuralScore
      ,try_cast([Confidence In Management Score] as int) as ManagementScore
      ,try_cast([Rating Value] as int) as Rating
      ,try_cast([Rating Date] as date) as RatingDate
      ,case
			when [New Rating Pending] = 'TRUE'
				then 1
			else 0
		end as NewRatingPending
      ,[Local Authority Business ID] as BusinessID
      ,[Ward Name] as WardName
      ,cast([Easting] as float) as Easting
      ,cast([Northing] as float) as Northing
      ,cast([Longitude] as float) as Long
      ,cast([Latitude] as float) as Lat
      ,[Spatial Accuracy] as Accuracy
      ,cast([Last Uploaded] as date) as LastUploaded
      --,geography::STPointFromText('POINT(' + CAST([Longitude] AS VARCHAR(10)) + ' ' + 
		--CAST([Latitude] AS VARCHAR(10)) + ')', 4326) as Location

	into dbo.CleansedBusinesses
  FROM [dbo].[Businesses]
GO

if OBJECT_ID('dbo.BusinessGeog') is not null
begin
	drop table dbo.BusinessGeog
end
go

select 
	 *
	,geometry::STPointFromText('POINT(' + CAST(Long AS VARCHAR(10)) + ' ' + 
		CAST(Lat AS VARCHAR(10)) + ')', 4326) as Location
into dbo.BusinessGeog
from dbo.CleansedBusinesses
go

if OBJECT_ID('dbo.BusinessLSOAPairs') is not null
begin
	drop table dbo.BusinessLSOAPairs
end
go

select
	 t.Code
	,t.Name
	,g.Business
	,g.BusinessID
	,g.HygieneScore
	,g.StructuralScore
	,g.ManagementScore
	,g.Rating
into BusinessLSOAPairs
from dbo.Test as t join dbo.BusinessGeog as g
	on t.LSOAGeog.STContains(g.Location) = 1
where 1=1
	and g.HygieneScore is not null
	and g.StructuralScore is not null
	and g.ManagementScore is not null
	and g.Rating is not null

select distinct
	 Code
	,Name
	,avg(HygieneScore) over (Partition by Code) as AvgHygiene
	,avg(StructuralScore) over (Partition by Code) as AvgStructural
	,avg(ManagementScore) over (Partition by Code) as AvgManagement
	,avg(Rating) over (Partition by Code) as AvgRating
from BusinessLSOAPairs
order by AvgHygiene desc

if OBJECT_ID('dbo.GeogFinal') is not null
begin
	drop table dbo.GeogFinal
end
go

select
	 [LSOA 2011 Code] as Code
	,[LSOA 2011 Name] as Name
	,the_geom as Geom
	,geometry::STPolyFromText(replace([the_geom],'linestring ', 'polygon (')+')',4326) as LSOAGeog
	,geometry::STLineFromText([the_geom],4326) as LSOAGeog2
into dbo.GeogFinal
from dbo.Boundaries

select
	LSOAGeog
from dbo.GeogFinal
