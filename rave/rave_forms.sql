select dbo.fnlocaldefault(FolderName), fr.oid 
from datapages dpg 
inner join dbo.Forms fr on fr.formId=dpg.FormId
inner join records rc on rc.DatapageId=dpg.DataPageId
inner join DataPoints dp on dp.RecordId=rc.RecordId
inner join fields f on f.FieldId=dp.FieldId
inner join subjects s on s.SubjectId=dpg.SubjectId
inner join folders fl on fl.CRFVersionID=s.CRFVersionID
where  dbo.fnlocaldefault(FolderName) like '%visit%'
and fr.oid='vs2'
and fr.formactive=1