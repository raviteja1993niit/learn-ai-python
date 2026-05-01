# PowerShell Script to Compare Modernization vs Target Environment Logs
# Detailed analysis of TSPI and ISO 8583 requests for Auth, Void Auth, and Verify operations

param(
    [string]$OutputPath = "$PSScriptRoot\environment-logs-detailed-comparison.csv"
)

$results = @()

# Manually extracted TSPI fields for each operation from the logs

# AUTHORIZATION TSPI Fields
$authModernTSPIFields = @(
    "MerchantContext.Acquirer.AcquirerId",
    "MerchantContext.Merchant.Address",
    "MerchantContext.Merchant.CategoryCode",
    "MerchantContext.Merchant.City",
    "MerchantContext.Merchant.CountryCode",
    "MerchantContext.Merchant.MerchantId",
    "MerchantContext.Merchant.MsoId",
    "MerchantContext.Merchant.Name",
    "MerchantContext.Merchant.PhoneNumber",
    "MerchantContext.Merchant.Postcode",
    "MerchantContext.Merchant.State",
    "MerchantContext.Merchant.Street2",
    "MerchantContext.Merchant.SubMerchant",
    "MerchantContext.MerchantAcquirerRelationship.AcquirerMerchantId",
    "MerchantContext.MerchantAcquirerRelationship.CategoryCode",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionFrequency",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionSource",
    "MerchantContext.MerchantAcquirerRelationship.TestMode",
    "MerchantContext.MerchantAcquirerRelationship.MerchantAcquirerCustomFields",
    "RoutingHeader.Action",
    "RoutingHeader.ActionType",
    "RoutingHeader.SourceId",
    "RoutingHeader.Timeout",
    "RoutingHeader.Version",
    "Transaction.currentInstallmentIterationNumber",
    "Transaction.numberOfAgreedRecurringPayments",
    "Transaction.recurringAmountVariability",
    "Transaction.AcceptPartialApproval",
    "Transaction.AcsECI",
    "Transaction.AcsReference",
    "Transaction.AcsTransactionId",
    "Transaction.AgreementId",
    "Transaction.AgreementType",
    "Transaction.Amount",
    "Transaction.AuthenticationProtocolVersion",
    "Transaction.AuthenticationToken",
    "Transaction.AuthenticationTransactionId",
    "Transaction.AuthorisationAmount",
    "Transaction.CaptureAmount",
    "Transaction.CardExpiryDate",
    "Transaction.CardNumber",
    "Transaction.CardType",
    "Transaction.CardholderActivatedTerminal",
    "Transaction.CurrencyCode",
    "Transaction.DsReference",
    "Transaction.DsTransactionId",
    "Transaction.FundingMethod",
    "Transaction.MerchantCategoryCode",
    "Transaction.MerchantOrderReference",
    "Transaction.MerchantPaymentGatewayID",
    "Transaction.OrderAmount",
    "Transaction.OrderCertainty",
    "Transaction.OrderDate",
    "Transaction.OrderId",
    "Transaction.PrimaryAccountNumber",
    "Transaction.PsTransactionSource",
    "Transaction.PurchaseType",
    "Transaction.RefundAmount",
    "Transaction.Rrn",
    "Transaction.SourceTransactionId",
    "Transaction.Stan",
    "Transaction.TerminalId",
    "Transaction.TransactionDate",
    "Transaction.TransactionFrequency",
    "Transaction.TransactionSource",
    "Transaction.TransactionType",
    "Transaction.AgreementData.FirstTransactionOfAgreement",
    "Transaction.AssociatedTransaction",
    "Transaction.BillingAddress",
    "Transaction.PAN"
)

$authTargetTSPIFields = @(
    "MerchantContext.Acquirer.AcquirerId",
    "MerchantContext.Acquirer.AcquirerName",
    "MerchantContext.Acquirer.BatchFullLevel",
    "MerchantContext.Acquirer.BatchWarningLevel",
    "MerchantContext.Acquirer.Locale",
    "MerchantContext.Acquirer.TerminalType",
    "MerchantContext.Acquirer.Timezone",
    "MerchantContext.AcquirerBatchNumber",
    "MerchantContext.Merchant.Address",
    "MerchantContext.Merchant.CategoryCode",
    "MerchantContext.Merchant.City",
    "MerchantContext.Merchant.CountryCode",
    "MerchantContext.Merchant.CreationDate",
    "MerchantContext.Merchant.GoodsDescription",
    "MerchantContext.Merchant.HomeUrl",
    "MerchantContext.Merchant.Level5",
    "MerchantContext.Merchant.Locale",
    "MerchantContext.Merchant.MerchantId",
    "MerchantContext.Merchant.MsoId",
    "MerchantContext.Merchant.Name",
    "MerchantContext.Merchant.Postcode",
    "MerchantContext.Merchant.State",
    "MerchantContext.Merchant.Street2",
    "MerchantContext.Merchant.SupportedEMV3DSSchemes",
    "MerchantContext.Merchant.SupportsAmexSafeKey",
    "MerchantContext.Merchant.SupportsDinersProtectBuy",
    "MerchantContext.Merchant.SupportsJSecure",
    "MerchantContext.Merchant.SupportsMasterpass",
    "MerchantContext.Merchant.SupportsSecureCode",
    "MerchantContext.Merchant.SupportsVbV",
    "MerchantContext.Merchant.Timezone",
    "MerchantContext.MerchantAcquirerRelationship.AcquirerMerchantId",
    "MerchantContext.MerchantAcquirerRelationship.CategoryCode",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionFrequency",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionSource",
    "MerchantContext.MerchantAcquirerRelationship.EcIndicator",
    "MerchantContext.MerchantAcquirerRelationship.IdentCode",
    "MerchantContext.MerchantAcquirerRelationship.RecurringTypeDefault",
    "MerchantContext.MerchantAcquirerRelationship.RelationshipId",
    "MerchantContext.MerchantAcquirerRelationship.SmokeTest",
    "MerchantContext.MerchantAcquirerRelationship.TestMode",
    "MerchantContext.TerminalBatchNumber",
    "MerchantContext.TerminalId",
    "RoutingHeader.Action",
    "RoutingHeader.ActionType",
    "RoutingHeader.RequestId",
    "RoutingHeader.RequestUrl",
    "RoutingHeader.RetryCount",
    "RoutingHeader.SourceId",
    "RoutingHeader.Timeout",
    "RoutingHeader.Version",
    "Transaction.AcceptPartialApproval",
    "Transaction.AccountType",
    "Transaction.Amount",
    "Transaction.AuthorisationAmount",
    "Transaction.CSC",
    "Transaction.CaptureAmount",
    "Transaction.CardCountryOfIssue",
    "Transaction.CardExpiryDate",
    "Transaction.CardNumber",
    "Transaction.CardOnFile",
    "Transaction.CardScheme",
    "Transaction.CardSecurityCode",
    "Transaction.CardTrackPresent",
    "Transaction.CardType",
    "Transaction.CashAdvance",
    "Transaction.CpcLevel",
    "Transaction.CredentialOnFile",
    "Transaction.CurrencyCode",
    "Transaction.DccBaseAmount",
    "Transaction.DccEnabled",
    "Transaction.DeferredAuthorization",
    "Transaction.FundingMethod",
    "Transaction.GatewayEntryPoint",
    "Transaction.ManuallyAuthorised",
    "Transaction.MerchantCategoryCode",
    "Transaction.MerchantPaymentGatewayID",
    "Transaction.MerchantTransactionSource",
    "Transaction.OrderAmount",
    "Transaction.OrderCertainty",
    "Transaction.OrderCustomFields",
    "Transaction.OrderDate",
    "Transaction.OrderId",
    "Transaction.OrderNumber",
    "Transaction.PAN",
    "Transaction.PaymentType",
    "Transaction.PrimaryAccountNumber",
    "Transaction.PsTransactionSource",
    "Transaction.RecurringType",
    "Transaction.Referred",
    "Transaction.RefundAmount",
    "Transaction.Rrn",
    "Transaction.SourceTransactionId",
    "Transaction.Stan",
    "Transaction.TerminalId",
    "Transaction.TransactionDate",
    "Transaction.TransactionFrequency",
    "Transaction.TransactionId",
    "Transaction.TransactionNumber",
    "Transaction.TransactionSource",
    "Transaction.TransactionType"
)

# Compare AUTHORIZATION
$missingAuthFields = $authTargetTSPIFields | Where-Object { $_ -notin $authModernTSPIFields }
$extraAuthFields = $authModernTSPIFields | Where-Object { $_ -notin $authTargetTSPIFields }

if ($missingAuthFields.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "AUTHORIZATION"
        RequestType = "TSPI"
        Category = "Missing in Modernization"
        Fields = $missingAuthFields -join "; "
        FieldCount = $missingAuthFields.Count
        Severity = if ($missingAuthFields.Count -gt 10) { "HIGH" } else { "MEDIUM" }
    }
}

if ($extraAuthFields.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "AUTHORIZATION"
        RequestType = "TSPI"
        Category = "Extra in Modernization"
        Fields = $extraAuthFields -join "; "
        FieldCount = $extraAuthFields.Count
        Severity = "LOW"
    }
}

# VOID_AUTHORIZATION TSPI Fields
$voidModernTSPIFields = @(
    "MerchantContext.Acquirer.AcquirerId",
    "MerchantContext.Merchant.Address",
    "MerchantContext.Merchant.City",
    "MerchantContext.Merchant.CountryCode",
    "MerchantContext.Merchant.MerchantId",
    "MerchantContext.Merchant.MsoId",
    "MerchantContext.Merchant.Name",
    "MerchantContext.Merchant.PhoneNumber",
    "MerchantContext.Merchant.Postcode",
    "MerchantContext.Merchant.State",
    "MerchantContext.Merchant.Street2",
    "MerchantContext.Merchant.Timezone",
    "MerchantContext.Merchant.SubMerchant",
    "MerchantContext.MerchantAcquirerRelationship.AcquirerMerchantId",
    "MerchantContext.MerchantAcquirerRelationship.CategoryCode",
    "MerchantContext.MerchantAcquirerRelationship.TestMode",
    "MerchantContext.MerchantAcquirerRelationship.MerchantAcquirerCustomFields",
    "RoutingHeader.Action",
    "RoutingHeader.ActionType",
    "RoutingHeader.SourceId",
    "RoutingHeader.Timeout",
    "RoutingHeader.Version",
    "Transaction.AcceptPartialApproval",
    "Transaction.Amount",
    "Transaction.AuthorisationAmount",
    "Transaction.CardExpiryDate",
    "Transaction.CardNumber",
    "Transaction.CardType",
    "Transaction.CardholderActivatedTerminal",
    "Transaction.CurrencyCode",
    "Transaction.FundingMethod",
    "Transaction.OrderDate",
    "Transaction.OrderId",
    "Transaction.PrimaryAccountNumber",
    "Transaction.Rrn",
    "Transaction.SourceTransactionId",
    "Transaction.Stan",
    "Transaction.TerminalId",
    "Transaction.TransactionDate",
    "Transaction.TransactionSource",
    "Transaction.TransactionType",
    "Transaction.AssociatedTransaction",
    "Transaction.PAN",
    "Transaction.TransactionsForThisOrder"
)

$voidTargetTSPIFields = @(
    "MerchantContext.Acquirer.AcquirerId",
    "MerchantContext.Acquirer.AcquirerName",
    "MerchantContext.Acquirer.BatchFullLevel",
    "MerchantContext.Acquirer.BatchWarningLevel",
    "MerchantContext.Acquirer.Locale",
    "MerchantContext.Acquirer.TerminalType",
    "MerchantContext.Acquirer.Timezone",
    "MerchantContext.AcquirerBatchNumber",
    "MerchantContext.Merchant.Address",
    "MerchantContext.Merchant.CategoryCode",
    "MerchantContext.Merchant.City",
    "MerchantContext.Merchant.CountryCode",
    "MerchantContext.Merchant.CreationDate",
    "MerchantContext.Merchant.GoodsDescription",
    "MerchantContext.Merchant.HomeUrl",
    "MerchantContext.Merchant.Level5",
    "MerchantContext.Merchant.Locale",
    "MerchantContext.Merchant.MerchantId",
    "MerchantContext.Merchant.MsoId",
    "MerchantContext.Merchant.Name",
    "MerchantContext.Merchant.Postcode",
    "MerchantContext.Merchant.State",
    "MerchantContext.Merchant.Street2",
    "MerchantContext.Merchant.SupportedEMV3DSSchemes",
    "MerchantContext.Merchant.SupportsAmexSafeKey",
    "MerchantContext.Merchant.SupportsDinersProtectBuy",
    "MerchantContext.Merchant.SupportsJSecure",
    "MerchantContext.Merchant.SupportsMasterpass",
    "MerchantContext.Merchant.SupportsSecureCode",
    "MerchantContext.Merchant.SupportsVbV",
    "MerchantContext.Merchant.Timezone",
    "MerchantContext.MerchantAcquirerRelationship.AcquirerMerchantId",
    "MerchantContext.MerchantAcquirerRelationship.CategoryCode",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionFrequency",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionSource",
    "MerchantContext.MerchantAcquirerRelationship.EcIndicator",
    "MerchantContext.MerchantAcquirerRelationship.IdentCode",
    "MerchantContext.MerchantAcquirerRelationship.RecurringTypeDefault",
    "MerchantContext.MerchantAcquirerRelationship.RelationshipId",
    "MerchantContext.MerchantAcquirerRelationship.SmokeTest",
    "MerchantContext.MerchantAcquirerRelationship.TestMode",
    "MerchantContext.TerminalBatchNumber",
    "MerchantContext.TerminalId",
    "RoutingHeader.Action",
    "RoutingHeader.ActionType",
    "RoutingHeader.RequestId",
    "RoutingHeader.RequestUrl",
    "RoutingHeader.RetryCount",
    "RoutingHeader.SourceId",
    "RoutingHeader.Timeout",
    "RoutingHeader.Version",
    "Transaction.AcceptPartialApproval",
    "Transaction.AccountType",
    "Transaction.Amount",
    "Transaction.AssociatedTransaction",
    "Transaction.AuthorisationAmount",
    "Transaction.AuthorisationId",
    "Transaction.CaptureAmount",
    "Transaction.CardCountryOfIssue",
    "Transaction.CardExpiryDate",
    "Transaction.CardNumber",
    "Transaction.CardOnFile",
    "Transaction.CardScheme",
    "Transaction.CardTrackPresent",
    "Transaction.CardType",
    "Transaction.CashAdvance",
    "Transaction.CpcLevel",
    "Transaction.CurrencyCode",
    "Transaction.DccBaseAmount",
    "Transaction.DccEnabled",
    "Transaction.DeferredAuthorization",
    "Transaction.FinancialNetworkDate",
    "Transaction.FinancialNetworkTransactionId",
    "Transaction.FundingMethod",
    "Transaction.GatewayEntryPoint",
    "Transaction.Level3Enabled",
    "Transaction.ManuallyAuthorised",
    "Transaction.MerchantCategoryCode",
    "Transaction.MerchantPaymentGatewayID",
    "Transaction.MerchantTransactionSource",
    "Transaction.OrderAmount",
    "Transaction.OrderCertainty",
    "Transaction.OrderCustomFields",
    "Transaction.OrderDate",
    "Transaction.OrderId",
    "Transaction.OrderNumber",
    "Transaction.PAN",
    "Transaction.PaymentType",
    "Transaction.PrimaryAccountNumber",
    "Transaction.PsTransactionSource",
    "Transaction.RecurringType",
    "Transaction.Referred",
    "Transaction.RefundAmount",
    "Transaction.Rrn",
    "Transaction.SourceTransactionId",
    "Transaction.Stan",
    "Transaction.TerminalId",
    "Transaction.TransactionDate",
    "Transaction.TransactionFrequency",
    "Transaction.TransactionId",
    "Transaction.TransactionNumber",
    "Transaction.TransactionSource",
    "Transaction.TransactionType",
    "Transaction.TransactionsForThisOrder"
)

# Compare VOID_AUTHORIZATION
$missingVoidFields = $voidTargetTSPIFields | Where-Object { $_ -notin $voidModernTSPIFields }
$extraVoidFields = $voidModernTSPIFields | Where-Object { $_ -notin $voidTargetTSPIFields }

if ($missingVoidFields.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VOID_AUTHORIZATION"
        RequestType = "TSPI"
        Category = "Missing in Modernization"
        Fields = $missingVoidFields -join "; "
        FieldCount = $missingVoidFields.Count
        Severity = if ($missingVoidFields.Count -gt 10) { "HIGH" } else { "MEDIUM" }
    }
}

if ($extraVoidFields.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VOID_AUTHORIZATION"
        RequestType = "TSPI"
        Category = "Extra in Modernization"
        Fields = $extraVoidFields -join "; "
        FieldCount = $extraVoidFields.Count
        Severity = "LOW"
    }
}

# VERIFICATION TSPI Fields
$verifyModernTSPIFields = @(
    "MerchantContext.Acquirer.AcquirerId",
    "MerchantContext.Merchant.Address",
    "MerchantContext.Merchant.City",
    "MerchantContext.Merchant.CountryCode",
    "MerchantContext.Merchant.MerchantId",
    "MerchantContext.Merchant.MsoId",
    "MerchantContext.Merchant.Name",
    "MerchantContext.Merchant.Postcode",
    "MerchantContext.Merchant.State",
    "MerchantContext.Merchant.Street2",
    "MerchantContext.Merchant.Timezone",
    "MerchantContext.Merchant.SubMerchant",
    "MerchantContext.MerchantAcquirerRelationship.AcquirerMerchantId",
    "MerchantContext.MerchantAcquirerRelationship.TestMode",
    "MerchantContext.MerchantAcquirerRelationship.MerchantAcquirerCustomFields",
    "RoutingHeader.Action",
    "RoutingHeader.ActionType",
    "RoutingHeader.SourceId",
    "RoutingHeader.Timeout",
    "RoutingHeader.Version",
    "Transaction.recurringAmountVariability",
    "Transaction.AcceptPartialApproval",
    "Transaction.AcsECI",
    "Transaction.AcsReference",
    "Transaction.AcsTransactionId",
    "Transaction.AgreementId",
    "Transaction.Amount",
    "Transaction.AuthenticationProtocolVersion",
    "Transaction.AuthenticationToken",
    "Transaction.AuthenticationTransactionId",
    "Transaction.AuthenticationTransactionStatus",
    "Transaction.AuthorisationAmount",
    "Transaction.CaptureAmount",
    "Transaction.CardExpiryDate",
    "Transaction.CardNumber",
    "Transaction.CardType",
    "Transaction.CredentialOnFile",
    "Transaction.CurrencyCode",
    "Transaction.DsReference",
    "Transaction.FundingMethod",
    "Transaction.MerchantCategoryCode",
    "Transaction.OrderCertainty",
    "Transaction.OrderDate",
    "Transaction.OrderId",
    "Transaction.PrimaryAccountNumber",
    "Transaction.PsTransactionSource",
    "Transaction.PurchaseType",
    "Transaction.RefundAmount",
    "Transaction.Rrn",
    "Transaction.SourceTransactionId",
    "Transaction.Stan",
    "Transaction.TerminalId",
    "Transaction.TransactionDate",
    "Transaction.TransactionFrequency",
    "Transaction.TransactionSource",
    "Transaction.TransactionType",
    "Transaction.AgreementData.FirstTransactionOfAgreement",
    "Transaction.AssociatedTransaction",
    "Transaction.BillingAddress",
    "Transaction.PAN"
)

$verifyTargetTSPIFields = @(
    "MerchantContext.Acquirer.AcquirerId",
    "MerchantContext.Acquirer.AcquirerName",
    "MerchantContext.Acquirer.BatchFullLevel",
    "MerchantContext.Acquirer.BatchWarningLevel",
    "MerchantContext.Acquirer.Locale",
    "MerchantContext.Acquirer.TerminalType",
    "MerchantContext.Acquirer.Timezone",
    "MerchantContext.AcquirerBatchNumber",
    "MerchantContext.Merchant.Address",
    "MerchantContext.Merchant.CategoryCode",
    "MerchantContext.Merchant.City",
    "MerchantContext.Merchant.CountryCode",
    "MerchantContext.Merchant.CreationDate",
    "MerchantContext.Merchant.GoodsDescription",
    "MerchantContext.Merchant.HomeUrl",
    "MerchantContext.Merchant.Level5",
    "MerchantContext.Merchant.Locale",
    "MerchantContext.Merchant.MerchantId",
    "MerchantContext.Merchant.MsoId",
    "MerchantContext.Merchant.Name",
    "MerchantContext.Merchant.Postcode",
    "MerchantContext.Merchant.State",
    "MerchantContext.Merchant.Street2",
    "MerchantContext.Merchant.SupportedEMV3DSSchemes",
    "MerchantContext.Merchant.SupportsAmexSafeKey",
    "MerchantContext.Merchant.SupportsDinersProtectBuy",
    "MerchantContext.Merchant.SupportsJSecure",
    "MerchantContext.Merchant.SupportsMasterpass",
    "MerchantContext.Merchant.SupportsSecureCode",
    "MerchantContext.Merchant.SupportsVbV",
    "MerchantContext.Merchant.Timezone",
    "MerchantContext.MerchantAcquirerRelationship.AcquirerMerchantId",
    "MerchantContext.MerchantAcquirerRelationship.CategoryCode",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionFrequency",
    "MerchantContext.MerchantAcquirerRelationship.DefaultTransactionSource",
    "MerchantContext.MerchantAcquirerRelationship.EcIndicator",
    "MerchantContext.MerchantAcquirerRelationship.IdentCode",
    "MerchantContext.MerchantAcquirerRelationship.RecurringTypeDefault",
    "MerchantContext.MerchantAcquirerRelationship.RelationshipId",
    "MerchantContext.MerchantAcquirerRelationship.SmokeTest",
    "MerchantContext.MerchantAcquirerRelationship.TestMode",
    "MerchantContext.TerminalBatchNumber",
    "MerchantContext.TerminalId",
    "RoutingHeader.Action",
    "RoutingHeader.ActionType",
    "RoutingHeader.RequestId",
    "RoutingHeader.RetryCount",
    "RoutingHeader.SourceId",
    "RoutingHeader.Timeout",
    "RoutingHeader.Version",
    "Transaction.AcceptPartialApproval",
    "Transaction.AccountType",
    "Transaction.AcquirerECI",
    "Transaction.AcsECI",
    "Transaction.AgreementId",
    "Transaction.AgreementType",
    "Transaction.Amount",
    "Transaction.AuthenticationAmount",
    "Transaction.AuthenticationState",
    "Transaction.AuthenticationStatusCode",
    "Transaction.AuthenticationToken",
    "Transaction.AuthenticationTransactionId",
    "Transaction.AuthenticationTransactionStatus",
    "Transaction.AuthenticationType",
    "Transaction.AuthenticationVersion",
    "Transaction.AuthorisationAmount",
    "Transaction.CSC",
    "Transaction.CaptureAmount",
    "Transaction.CardCountryOfIssue",
    "Transaction.CardExpiryDate",
    "Transaction.CardNumber",
    "Transaction.CardOnFile",
    "Transaction.CardScheme",
    "Transaction.CardSecurityCode",
    "Transaction.CardTrackPresent",
    "Transaction.CardType",
    "Transaction.CashAdvance",
    "Transaction.Cavv",
    "Transaction.CpcLevel",
    "Transaction.CredentialOnFile",
    "Transaction.CurrencyCode",
    "Transaction.DccBaseAmount",
    "Transaction.DccEnabled",
    "Transaction.DeferredAuthorization",
    "Transaction.DsTransactionId",
    "Transaction.FundingMethod",
    "Transaction.GatewayEntryPoint",
    "Transaction.ManuallyAuthorised",
    "Transaction.MerchantCategoryCode",
    "Transaction.MerchantPaymentGatewayID",
    "Transaction.MerchantTransactionSource",
    "Transaction.OrderAmount",
    "Transaction.OrderCustomFields",
    "Transaction.OrderDate",
    "Transaction.OrderId",
    "Transaction.OrderNumber",
    "Transaction.PAN",
    "Transaction.PaymentType",
    "Transaction.PrimaryAccountNumber",
    "Transaction.PsTransactionSource",
    "Transaction.RecPayAgreement",
    "Transaction.RecurringType",
    "Transaction.Referred",
    "Transaction.RefundAmount",
    "Transaction.Rrn",
    "Transaction.SourceTransactionId",
    "Transaction.Stan",
    "Transaction.TerminalId",
    "Transaction.TransactionDate",
    "Transaction.TransactionFrequency",
    "Transaction.TransactionId",
    "Transaction.TransactionNumber",
    "Transaction.TransactionSource",
    "Transaction.TransactionType",
    "Transaction.VdsResponse",
    "Transaction.recurringAmountVariability"
)

# Compare VERIFICATION
$missingVerifyFields = $verifyTargetTSPIFields | Where-Object { $_ -notin $verifyModernTSPIFields }
$extraVerifyFields = $verifyModernTSPIFields | Where-Object { $_ -notin $verifyTargetTSPIFields }

if ($missingVerifyFields.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VERIFICATION"
        RequestType = "TSPI"
        Category = "Missing in Modernization"
        Fields = $missingVerifyFields -join "; "
        FieldCount = $missingVerifyFields.Count
        Severity = if ($missingVerifyFields.Count -gt 10) { "HIGH" } else { "MEDIUM" }
    }
}

if ($extraVerifyFields.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VERIFICATION"
        RequestType = "TSPI"
        Category = "Extra in Modernization"
        Fields = $extraVerifyFields -join "; "
        FieldCount = $extraVerifyFields.Count
        Severity = "LOW"
    }
}

# ISO 8583 Fields Analysis
# Authorization ISO 8583 Missing Fields
$iso8583MissingAuth = @("002 (cvv2)", "038 (approvalCode)", "044 (scaStatusIndicator)")

if ($iso8583MissingAuth.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "AUTHORIZATION"
        RequestType = "ISO 8583 Field 063"
        Category = "Missing in Modernization"
        Fields = $iso8583MissingAuth -join "; "
        FieldCount = $iso8583MissingAuth.Count
        Severity = "HIGH"
    }
}

# Void Authorization ISO 8583 Missing Fields
$iso8583MissingVoid = @("038 (approvalCode)", "016 (cardSchemeData)", "002 (cvv2)", "044 (scaStatusIndicator)")

if ($iso8583MissingVoid.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VOID_AUTHORIZATION"
        RequestType = "ISO 8583 Field 063"
        Category = "Missing in Modernization"
        Fields = $iso8583MissingVoid -join "; "
        FieldCount = $iso8583MissingVoid.Count
        Severity = "HIGH"
    }
}

# Verification ISO 8583 Missing Fields
$iso8583MissingVerify = @("044 (scaStatusIndicator)", "065 (mastercardMerchantPaymentGatewayID)")

if ($iso8583MissingVerify.Count -gt 0) {
    $results += [PSCustomObject]@{
        Operation = "VERIFICATION"
        RequestType = "ISO 8583 Field 063"
        Category = "Missing in Modernization"
        Fields = $iso8583MissingVerify -join "; "
        FieldCount = $iso8583MissingVerify.Count
        Severity = "MEDIUM"
    }
}

# Export to CSV with proper formatting
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "✓ Analysis complete!" -ForegroundColor Green
    Write-Host "✓ CSV file created: $OutputPath" -ForegroundColor Green
    Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Total Differences Found: $($results.Count)" -ForegroundColor Yellow

    # Count by operation
    $authDiff = @($results | Where-Object {$_.Operation -eq 'AUTHORIZATION'}).Count
    $voidDiff = @($results | Where-Object {$_.Operation -eq 'VOID_AUTHORIZATION'}).Count
    $verifyDiff = @($results | Where-Object {$_.Operation -eq 'VERIFICATION'}).Count

    Write-Host "  - AUTHORIZATION: $authDiff difference(s)" -ForegroundColor Yellow
    Write-Host "  - VOID_AUTHORIZATION: $voidDiff difference(s)" -ForegroundColor Yellow
    Write-Host "  - VERIFICATION: $verifyDiff difference(s)" -ForegroundColor Yellow

    # Count by severity
    Write-Host "`n=== SEVERITY BREAKDOWN ===" -ForegroundColor Cyan
    $highSev = @($results | Where-Object {$_.Severity -eq 'HIGH'}).Count
    $medSev = @($results | Where-Object {$_.Severity -eq 'MEDIUM'}).Count
    $lowSev = @($results | Where-Object {$_.Severity -eq 'LOW'}).Count

    Write-Host "  - HIGH: $highSev issue(s)" -ForegroundColor Red
    Write-Host "  - MEDIUM: $medSev issue(s)" -ForegroundColor Magenta
    Write-Host "  - LOW: $lowSev issue(s)" -ForegroundColor Yellow

    # Display CSV content
    Write-Host "`n=== CSV CONTENT ===" -ForegroundColor Cyan
    Import-Csv -Path $OutputPath | Format-Table -AutoSize -Wrap

} else {
    Write-Host "No differences found." -ForegroundColor Green
}

