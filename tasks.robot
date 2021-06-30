*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocloud.Secrets

*** Variables ***
${GLOBAL_RETRY_AMOUNT}    5x
${GLOBAL_RETRY_INTERVAL}    0.5s

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    url
    Open Available Browser    ${secret}[url]

*** Keywords ****
Close the annoying modal
    Click Button    class:btn-dark

*** Keywords ***
Get orders
    [Arguments]    ${URL}
    Download    ${URL}    overwrite=True
    ${orders}=  Read table from CSV    orders.csv
    [Return]    ${orders}

*** Keywords ****
Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head  ${order}[Head]
    Input Text    id:address    ${order}[Address]
    Input Text    css:input[placeholder="Enter the part number for the legs"]   ${order}[Legs]  
    Select Radio Button     body     ${order}[Body]

*** Keywords ****
Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

*** Keywords ****
Submit the order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

*** Keywords ***
Submit the order - Retry
    Wait Until Keyword Succeeds   ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order

*** Keywords ****
Store the receipt as a PDF file
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}${order}.pdf
    ${pdf}    Set Variable    ${CURDIR}${/}output${/}${order}.pdf
    [Return]    ${pdf}

*** Keywords ****
Take a screenshot of the robot
    [Arguments]    ${order}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${order}.png
    ${screenshot}    Set Variable    ${CURDIR}${/}output${/}${order}.png
    [Return]    ${screenshot}

*** Keywords ****
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log     ${pdf}
    Open Pdf    ${pdf}   
    Add Watermark Image To Pdf  ${screenshot}   ${pdf}
    Close Pdf

*** Keywords ****
Go to order another robot
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    Wait Until Element Is Visible   class:btn-dark

*** Keywords ****
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}      orders.zip

*** Keywords ****
Get URL From User
    ${URL} =	Get Value From User    Please provide the URL of the orders.csv! 
    [Return]    ${URL}

*** Keywords ****
Log Out And Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc 
    ${URL} =	Get URL From User
    Open the robot order website
    ${orders}=  Get orders  ${URL}
    FOR    ${order}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${order}
         Preview the robot
         Submit the order - Retry
         ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
         Log    ${pdf}
         Log    ${screenshot}
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log Out And Close The Browser



