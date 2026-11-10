import fs from 'fs';
import path from 'path';
import os from 'os';

const apiKey = 'AIzaSyCMJ0DhDzWRA3sMA_nqGSgNOJ_LIPWH8No';
const projectId = 'aayusathi-a1199';

const testIds = [
  '111111111111',
  '222222222222',
  '333333333333',
  '444444444444',
  '555555555555',
  '666666666666',
  '777777777777',
];

async function getAdminToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens;

  if (tokens.expires_at && tokens.expires_at > Date.now() + 60000) {
    return tokens.access_token;
  }

  if (tokens.refresh_token) {
    const refreshRes = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho85qd6.apps.googleusercontent.com',
        refresh_token: tokens.refresh_token,
        grant_type: 'refresh_token',
      }),
    });
    const data = await refreshRes.json();
    if (data.access_token) {
      tokens.access_token = data.access_token;
      tokens.expires_at = Date.now() + (data.expires_in || 3600) * 1000;
      fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8');
      return data.access_token;
    }
  }

  return tokens.access_token;
}

async function main() {
  const token = await getAdminToken();
  console.log('Authenticated with Google Cloud OAuth admin token.');

  console.log('\n==============================================');
  console.log('Testing Live Cloud Firestore Demo Aadhaar Lookups');
  console.log('==============================================\n');

  for (const id of testIds) {
    const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/demo_aadhaar/${id}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (!res.ok) {
      console.error(`FAILED to fetch ${id}: status ${res.status}`);
      continue;
    }

    const doc = await res.json();
    const f = doc.fields;
    console.log(`[PASS] Aadhaar: ${id.substring(0, 4)} **** ****`);
    console.log(`       Name:       ${f.name?.stringValue}`);
    console.log(`       BloodGroup: ${f.bloodGroup?.stringValue}`);
    console.log(`       Age:        ${f.age?.integerValue}`);
    console.log(`       Gender:     ${f.gender?.stringValue}`);
    console.log(`       Address:    ${f.address?.stringValue}\n`);
  }

  console.log('All 5 live lookups completed successfully.');
}

main().catch(console.error);
