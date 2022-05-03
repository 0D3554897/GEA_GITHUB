-- Added CR-5568
-- Active flag= Y will allow us to calculate the rate within reclass process
-- Active Flag= N will allow Costpoint to calculate the rate based on pay_types

UPDATE XX_ET_EXCLUDE_PROJECTS
SET active_fl='Y'
where proj_abbrv_cd in ('AD16','SD16','OA1M','OS1M')

UPDATE XX_ET_EXCLUDE_PROJECTS
SET active_fl='N'
where proj_abbrv_cd in ('OD16','OD1M')
