declare @currentSettings NVARCHAR(max) = (
    select replace(replace(JSON_Query(Configurations, '$[2].settings'), '[',''),']','')   
    from Config.ClientSetting
)


set @currentSettings = @currentSettings + ',{
    "AccessLevel": "curriqunet",
    "DataType": "bool",
    "Description": "This will enable the Contributors flyout feature on Maverick",
    "Default": false,
    "Label": "Enable Maverick Co-Contributors",
    "Name": "EnableFlyoutCoContributors",
    "Value": true,
    "Active": true
}'

set @currentSettings = CONCAT('[',@currentSettings,']')


update Config.ClientSetting
set Configurations = JSON_MODIFY(Configurations, '$[2].settings',JSON_QUERY(@currentSettings))

select Configurations from Config.ClientSetting