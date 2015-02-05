select cdo.DatabaseObject
	, cds.FormatName
	, cds.Header
	, cds.RowTemplate
from WebServicesConfigurableDatasetObjects cdo
inner join WebServicesConfigurableDatasetFormats cds on cds.ConfigurationId=cdo.ConfigurationId
where cdo.DatabaseObject like 'spCtms%'