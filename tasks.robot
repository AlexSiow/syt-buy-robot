*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    ${orderfile}=    Get order file
    Download    ${orderfile}    overwrite=True
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Wait Until Element Is Visible    css:#root > div > div.modal > div > div > div > div
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    css:#root > div > div.container > div > div.col-sm-7 > form
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:.form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Go to order another robot
    Click Button    order-another

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    order
    Assert order submitted

Assert order submitted
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${ordernumber}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipts${/}${ordernumber}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}${ordernumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${ordernumber}
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(1)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(2)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}preview${/}${ordernumber}.png
    [Return]    ${OUTPUT_DIR}${/}preview${/}${ordernumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${robot}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${robot}    ${pdf}

Create a ZIP file of the receipts
    ${zip_receipt_filename}=    Set Variable    ${OUTPUT_DIR}${/}Robot_Receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${zip_receipt_filename}

Get order file
    ${orderfile}=    Get Secret    order
    Add text input    orderfile    Order file location    ${orderfile}[orderfile]
    ${response}=    Run dialog
    [Return]    ${response.orderfile}
