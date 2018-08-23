%Written by Craig Risien (crisien@coas.oregonstate.edu) on 2018/05/28 using
%Matlab2018a
%This script will get, plot and save all the recovered CTD data for the OOI Southern
%Ocean Flanking Mooring A for 2015-01-01 - 2016-12-31.
%To get GS Flanking Mooring B data use the following code:

% for ii = 60:71  %get all 12 ctds off flanking mooring B
%     
%     filename = strcat('GS_FLMB_CTD_',num2str(ii));
%
%     %async call to the OOI API. Uframe should produce ~3 .nc files. One per deployment.
%     if ii < 69
%         m2m_url = strcat('https://ooinet.oceanobservatories.org/api/m2m/12576/sensor/inv/GS03FLMB/RIM01/02-CTDMOG0',num2str(ii),'/recovered_inst/ctdmo_ghqr_instrument_recovered?beginDT=2015-01-01T00:00:00.000Z&endDT=2016-12-31T23:59:59.999Z');
%     else
%         m2m_url = strcat('https://ooinet.oceanobservatories.org/api/m2m/12576/sensor/inv/GS03FLMB/RIM01/02-CTDMOH0',num2str(ii),'/recovered_inst/ctdmo_ghqr_instrument_recovered?beginDT=2015-01-01T00:00:00.000Z&endDT=2016-12-31T23:59:59.999Z');
%     end
% 
%     m2m_response = urlread(m2m_url, 'Authentication', 'Basic', 'Username', 'OOIAPI-D8S960UXPK4K03', 'Password', 'IXL48EQ2XY');
%
%     ......

clear all
close all

for ii = 40:51  %get all 12 ctds off flanking mooring A
    
    filename = strcat('GS_FLMA_CTD_',num2str(ii));
    
    %async call to the OOI API. Uframe should produce ~3 .nc files. One per deployment.
    if ii < 49
        m2m_url = strcat('https://ooinet.oceanobservatories.org/api/m2m/12576/sensor/inv/GS03FLMA/RIM01/02-CTDMOG0',num2str(ii),'/recovered_inst/ctdmo_ghqr_instrument_recovered?beginDT=2015-01-01T00:00:00.000Z&endDT=2016-12-31T23:59:59.999Z');
    else
        m2m_url = strcat('https://ooinet.oceanobservatories.org/api/m2m/12576/sensor/inv/GS03FLMA/RIM01/02-CTDMOH0',num2str(ii),'/recovered_inst/ctdmo_ghqr_instrument_recovered?beginDT=2015-01-01T00:00:00.000Z&endDT=2016-12-31T23:59:59.999Z');
    end
    
    m2m_response = urlread(m2m_url, 'Authentication', 'Basic', 'Username', 'OOIAPI-D8S960UXPK4K03', 'Password', 'IXL48EQ2XY');
    m2m_response = jsondecode(m2m_response);
    catalog_url=char(extractfield(m2m_response,'outputURL'));
    
    for k = 1:1000
        [str,status] = urlread(catalog_url);    %check to see if Uframe has produced the files yet
        if status
            disp('Data are now available')
            break
        else
            pause(1) %wait a second and try again
            disp(ii)
            disp(k)
        end
    end
    
    catalog=webread(catalog_url);
    nclist=regexp(catalog,'<a href=''([^>]+.nc)''>','tokens');
    base_url='https://opendap.oceanobservatories.org/thredds/dodsC/';
    time_array=[];salinity_array=[];pressure_array=[];density_array=[];temperature_array=[];

    for i = 1:length(nclist)

        url_thredds=nclist{1,i}{1,1};
        url_thredds=strcat(base_url,url_thredds(22:end));
        
        data=ncread(url_thredds,'time');
        time_array(length(time_array)+1:length(time_array)+length(data)) = data;
        clear data

        data=ncread(url_thredds,'ctdmo_seawater_pressure');
        pressure_array(length(pressure_array)+1:length(pressure_array)+length(data)) = data;
        clear data

        data=ncread(url_thredds,'ctdmo_seawater_temperature');
        temperature_array(length(temperature_array)+1:length(temperature_array)+length(data)) = data;
        clear data

        data=ncread(url_thredds,'practical_salinity');
        salinity_array(length(salinity_array)+1:length(salinity_array)+length(data)) = data;
        clear data

        data=ncread(url_thredds,'density');
        density_array(length(density_array)+1:length(density_array)+length(data)) = data;
        clear data

    end
    
    time_array=datenum(1900,1,1,0,0,0)+(time_array/60/60/24);
    plot(time_array,pressure_array)
    hold on
    
    save(filename, 'time_array', 'temperature_array', 'pressure_array', 'density_array', 'salinity_array');
    
end

title('Southern Ocean FLMA')
ylabel('dbar')
datetick('x')
