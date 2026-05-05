/**
 * TicketTool.cfc — MCP-exposed tool for filing support escalation tickets.
 * Sends an HTML email via cfmail when a ticket is filed.
 *
 * This CFC is registered with an MCP server. The AI calls fileTicket()
 * automatically through the MCP protocol when a customer needs escalation.
 *
 * Each remote method's hint, @mcpDescription, and param annotations are sent
 * to the LLM so it knows when and how to call the tool.
 *
 * Config: Set application.supportEmail and application.fromEmail in Application.cfc.
 *         CF Admin must have a mail server configured.
 */
component hint="MCP tool for filing Nexora support escalation tickets and sending email notifications" {

    /**
     * File a high-priority support escalation ticket and send an HTML email
     * notification to the support team. Use this when a customer explicitly
     * asks to escalate, expresses strong frustration, or asks to speak with
     * a manager. Do NOT use for routine order status questions.
     *
     * @mcpTool
     * @mcpDescription File a high-priority support escalation ticket and send an HTML email notification to the support team. Use this when a customer explicitly asks to escalate, expresses strong frustration, or asks to speak with a manager. Do NOT use for routine order status questions.
     * @hint File a high-priority escalation ticket and send email notification
     * @summary 1-2 sentence description of the customer issue being escalated
     * @orderId The related order ID if applicable (empty string if none)
     * @priority Ticket priority: low, medium, high, or critical
     * @returntype string
     */
    remote string function fileTicket(
        required string summary,
        string orderId  = "",
        string priority = "high"
    )
        hint="File a high-priority escalation ticket and send email notification"
    {
        local.ticketId  = "TKT-" & uCase(left(hash(now() & createUUID()), 6));
        local.filed     = dateTimeFormat(now(), "MMMM D, YYYY — h:mm tt");
        local.orderInfo = len(trim(arguments.orderId)) ? "##" & trim(arguments.orderId) & "##" : "N/A";

        local.badgeColor = (arguments.priority == "critical") ? "##cc0000" :
                           (arguments.priority == "high")     ? "##e65c00" :
                           (arguments.priority == "medium")   ? "##b38600" : "##357a38";

        local.html = "
<html><body style='font-family:Arial,sans-serif;color:##333;max-width:600px;margin:0 auto'>

  <div style='background:##FA0F00;padding:18px 24px;border-radius:8px 8px 0 0'>
    <h2 style='color:white;margin:0;font-size:18px'>Nexora — Support Ticket Filed via MCP</h2>
  </div>

  <div style='background:##f9f9f9;border:1px solid ##e0e0e0;border-top:none;padding:24px;border-radius:0 0 8px 8px'>
    <table style='width:100%;border-collapse:collapse;margin-bottom:20px'>
      <tr>
        <td style='padding:9px 12px;color:##666;width:120px;font-size:13px'>Ticket ID</td>
        <td style='padding:9px 12px;font-weight:bold;font-size:20px;font-family:monospace;letter-spacing:1px'>" & local.ticketId & "</td>
      </tr>
      <tr style='background:white;border-radius:4px'>
        <td style='padding:9px 12px;color:##666;font-size:13px'>Priority</td>
        <td style='padding:9px 12px'>
          <span style='background:" & local.badgeColor & ";color:white;padding:3px 12px;border-radius:20px;font-size:12px;font-weight:bold;letter-spacing:.5px'>" & uCase(arguments.priority) & "</span>
        </td>
      </tr>
      <tr>
        <td style='padding:9px 12px;color:##666;font-size:13px'>Order</td>
        <td style='padding:9px 12px;font-family:monospace'>" & local.orderInfo & "</td>
      </tr>
      <tr style='background:white'>
        <td style='padding:9px 12px;color:##666;font-size:13px'>Filed At</td>
        <td style='padding:9px 12px'>" & local.filed & "</td>
      </tr>
    </table>

    <div style='background:white;border:1px solid ##e0e0e0;border-left:4px solid ##FA0F00;border-radius:4px;padding:14px 18px'>
      <div style='font-size:11px;color:##999;text-transform:uppercase;letter-spacing:.6px;margin-bottom:6px'>Issue Summary</div>
      <div style='font-size:14px;line-height:1.6'>" & encodeforHTML(arguments.summary) & "</div>
    </div>

    <p style='margin-top:20px;font-size:12px;color:##888;border-top:1px solid ##e0e0e0;padding-top:14px'>
      This ticket was filed automatically by the <strong>Nexora AI Support Assistant</strong>
      using <strong>ColdFusion 2025 MCP (Model Context Protocol)</strong>.<br>
      Please respond to this customer within <strong>2 business hours</strong>.
    </p>
  </div>

</body></html>";

        local.emailSent = false;
        local.emailNote = "";
        try {
            local.toAddr   = application.supportEmail  ?: "support@example.com";
            local.fromAddr = application.fromEmail     ?: "noreply@example.com";
            cfmail(
                to      = local.toAddr,
                from    = local.fromAddr,
                subject = "[Nexora Support] " & local.ticketId & " — " & uCase(arguments.priority) & " Priority Escalation",
                type    = "html"
            ) {
                writeOutput(local.html);
            }
            local.emailSent = true;
            local.emailNote = "Email notification sent to " & local.toAddr & ".";
        } catch (any e) {
            local.emailNote = "(Email notification failed — " & e.message & ".)";
        }

        return "Escalation ticket ##" & local.ticketId & "## has been created with " &
               uCase(arguments.priority) & " priority. " & local.emailNote &
               " A senior support agent will follow up within 2 business hours.";
    }

}
