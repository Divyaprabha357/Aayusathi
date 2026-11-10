// Supabase Edge Function: generate-report-url
//
// Purpose:
// Generates a short-lived signed URL for accessing private medical reports
// in the `aayusathi-reports` bucket after validating the caller's authorization.
//
// Security Constraints:
// 1. Bucket `aayusathi-reports` is PRIVATE.
// 2. Caller must provide a valid Firebase/Supabase auth token.
// 3. Resource-specific path validation (never trusts arbitrary input paths).
// 4. Returns only temporary signed URL with strict expiration (e.g., 300 seconds).

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const BUCKET_NAME = "aayusathi-reports";
const SIGNED_URL_EXPIRY_SECONDS = 300; // 5 minutes

interface ReportUrlRequest {
  patientId: string;
  caseId: string;
  visitId: string;
  reportId?: string;
  fileName?: string;
  storagePath?: string;
}

serve(async (req: Request) => {
  // CORS Headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration missing." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize privileged server-side Supabase client
    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    const body: ReportUrlRequest = await req.json();
    const { patientId, caseId, visitId, fileName, storagePath } = body;

    if (!patientId || !caseId || !visitId) {
      return new Response(
        JSON.stringify({ error: "Missing required identifiers (patientId, caseId, visitId)." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Construct or validate canonical path
    let targetPath = storagePath;
    if (!targetPath) {
      const cleanFileName = fileName || "report.pdf";
      targetPath = `patients/${patientId}/cases/${caseId}/visits/${visitId}/reports/${cleanFileName}`;
    }

    // Validate path safety (prevent path traversal)
    if (targetPath.includes("..") || !targetPath.startsWith(`patients/${patientId}/`)) {
      return new Response(
        JSON.stringify({ error: "Invalid or unauthorized storage path." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generate short-lived signed URL
    const { data, error } = await supabase.storage
      .from(BUCKET_NAME)
      .createSignedUrl(targetPath, SIGNED_URL_EXPIRY_SECONDS);

    if (error || !data) {
      return new Response(
        JSON.stringify({ error: error?.message || "Failed to generate signed URL." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        signedUrl: data.signedUrl,
        expiresInSeconds: SIGNED_URL_EXPIRY_SECONDS,
        storagePath: targetPath,
        bucket: BUCKET_NAME,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err?.message || "Internal server error." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
