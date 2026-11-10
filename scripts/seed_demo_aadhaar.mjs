import fs from 'fs';
import path from 'path';
import os from 'os';

const PROJECT_ID = 'aayusathi-a1199';
const COLLECTION = 'demo_aadhaar';

const DEMO_RECORDS = [
  {
    docId: '111111111111',
    aadharNumber: '111111111111',
    name: 'Aarav Patil',
    bloodGroup: 'B+',
    age: 24,
    address: '12 Demo Lane, Vengurla, Maharashtra',
    gender: 'Male',
  },
  {
    docId: '222222222222',
    aadharNumber: '222222222222',
    name: 'Ananya Deshmukh',
    bloodGroup: 'O+',
    age: 31,
    address: '45 Test Road, Wadala, Mumbai',
    gender: 'Female',
  },
  {
    docId: '333333333333',
    aadharNumber: '333333333333',
    name: 'Rohan Kulkarni',
    bloodGroup: 'A+',
    age: 19,
    address: '78 Sample Nagar, Pune, Maharashtra',
    gender: 'Male',
  },
  {
    docId: '444444444444',
    aadharNumber: '444444444444',
    name: 'Meera Joshi',
    bloodGroup: 'AB+',
    age: 42,
    address: '23 Prototype Street, Nashik, Maharashtra',
    gender: 'Female',
  },
  {
    docId: '555555555555',
    aadharNumber: '555555555555',
    name: 'Kabir Shahi',
    bloodGroup: 'O-',
    age: 56,
    address: '91 Mock Colony, Thane, Maharashtra',
    gender: 'Male',
    dob: '30 Apr 1970',
  },
  {
    docId: '666666666666',
    aadharNumber: '666666666666',
    name: 'Yatin Ugale',
    bloodGroup: 'B+',
    age: 26,
    address: 'Nirmala Nagar, Khar Road, Mumbai',
    gender: 'Male',
    dob: '20 Oct 2000',
  },
  {
    docId: '777777777777',
    aadharNumber: '777777777777',
    name: 'Urvi Sharma',
    bloodGroup: 'A+',
    age: 24,
    address: 'Ram Nagar, Haryana',
    gender: 'Female',
    dob: '10 Aug 2002',
  },
];

const VALID_BLOOD_GROUPS = new Set(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']);
const VALID_GENDERS = new Set(['Male', 'Female', 'Other']);

function validateRecord(record) {
  if (!record.docId || record.docId !== record.aadharNumber) {
    throw new Error(`DocId must match aadharNumber: ${record.docId} !== ${record.aadharNumber}`);
  }
  if (!/^\d{12}$/.test(record.aadharNumber)) {
    throw new Error(`Aadhaar must be exactly 12 digits: ${record.aadharNumber}`);
  }
  if (!record.name || typeof record.name !== 'string' || record.name.trim().length === 0) {
    throw new Error(`Name must be a non-empty string: ${record.name}`);
  }
  if (!Number.isInteger(record.age) || record.age <= 0) {
    throw new Error(`Age must be a positive integer: ${record.age}`);
  }
  if (!VALID_GENDERS.has(record.gender)) {
    throw new Error(`Gender must be Male, Female, or Other: ${record.gender}`);
  }
  if (!VALID_BLOOD_GROUPS.has(record.bloodGroup)) {
    throw new Error(`Invalid blood group: ${record.bloodGroup}`);
  }
  if (!record.address || typeof record.address !== 'string' || record.address.trim().length === 0) {
    throw new Error(`Address must be a non-empty string: ${record.address}`);
  }
}

async function getAdminToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error(`Firebase credentials not found at ${configPath}. Run 'firebase login' first.`);
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens;
  if (!tokens || !tokens.access_token) {
    throw new Error('No access_token found in firebase-tools.json');
  }

  if (tokens.expires_at && tokens.expires_at > Date.now() + 60000) {
    return tokens.access_token;
  }

  // Refresh if needed
  if (tokens.refresh_token) {
    console.log('Refreshing Google OAuth access token...');
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

async function seedRecords() {
  console.log('==================================================');
  console.log(`AAYUSATHI: Seeding 5 Demo Aadhaar Records to Firebase`);
  console.log(`Project: ${PROJECT_ID} | Collection: ${COLLECTION}`);
  console.log('==================================================\n');

  // 1. Validate all records before sending
  for (const record of DEMO_RECORDS) {
    validateRecord(record);
    console.log(`✓ Record validated: ${record.aadharNumber.substring(0, 4)} **** **** (${record.name})`);
  }
  console.log('\nAll 5 records passed local validation.\n');

  // 2. Get Admin Auth Token
  const token = await getAdminToken();
  console.log('Authenticated with Firebase Admin OAuth token.');

  // 3. Write each record via Firestore REST API (PATCH creates or merges idempotently)
  for (const record of DEMO_RECORDS) {
    const docUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}/${record.docId}`;
    const body = {
      fields: {
        aadharNumber: { stringValue: record.aadharNumber },
        name: { stringValue: record.name },
        bloodGroup: { stringValue: record.bloodGroup },
        age: { integerValue: record.age.toString() },
        address: { stringValue: record.address },
        gender: { stringValue: record.gender },
        ...(record.dob ? { dob: { stringValue: record.dob } } : {}),
      },
    };

    const res = await fetch(docUrl, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Failed to write ${record.docId}: ${res.status} ${err}`);
    }

    console.log(`✓ Firestore write success: /${COLLECTION}/${record.docId} [${record.name}, ${record.gender}, ${record.age}y, ${record.bloodGroup}]`);
  }

  // 4. Verify collection contents
  console.log('\nVerifying collection documents from Cloud Firestore...');
  const verifyRes = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${COLLECTION}`,
    {
      headers: { Authorization: `Bearer ${token}` },
    }
  );

  if (!verifyRes.ok) {
    throw new Error(`Verification query failed: ${verifyRes.status} ${await verifyRes.text()}`);
  }

  const verifyData = await verifyRes.json();
  const docs = verifyData.documents || [];
  console.log(`Total documents found in /${COLLECTION}: ${docs.length}`);

  if (docs.length !== 7) {
    console.warn(`WARNING: Expected 7 documents, but found ${docs.length}`);
  }

  for (const doc of docs) {
    const docId = doc.name.split('/').pop();
    const f = doc.fields;
    console.log(` - Document: ${docId}`);
    console.log(`     name: ${f.name?.stringValue}`);
    console.log(`     bloodGroup: ${f.bloodGroup?.stringValue}`);
    console.log(`     age: ${f.age?.integerValue}`);
    console.log(`     gender: ${f.gender?.stringValue}`);
    console.log(`     address: ${f.address?.stringValue}`);
  }

  console.log('\n✓ Seeding and verification completed successfully!');
}

seedRecords().catch((err) => {
  console.error('Fatal error during seeding:', err);
  process.exit(1);
});
