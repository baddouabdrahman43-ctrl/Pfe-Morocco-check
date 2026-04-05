import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeApiBaseUrl, resolveApiBaseUrl } from './api.js';

test('normalizeApiBaseUrl trims trailing slashes and appends /api', () => {
  assert.equal(
    normalizeApiBaseUrl('https://admin.example.com/'),
    'https://admin.example.com/api'
  );
  assert.equal(
    normalizeApiBaseUrl('https://admin.example.com/api'),
    'https://admin.example.com/api'
  );
});

test('normalizeApiBaseUrl returns an empty string for blank values', () => {
  assert.equal(normalizeApiBaseUrl(''), '');
  assert.equal(normalizeApiBaseUrl('   '), '');
});

test('resolveApiBaseUrl falls back to same-origin /api on https hosts', () => {
  const previousWindow = globalThis.window;

  globalThis.window = {
    location: {
      hostname: 'dashboard.example.com',
      origin: 'https://dashboard.example.com',
      protocol: 'https:'
    }
  };

  try {
    assert.equal(resolveApiBaseUrl(), 'https://dashboard.example.com/api');
  } finally {
    if (previousWindow === undefined) {
      delete globalThis.window;
    } else {
      globalThis.window = previousWindow;
    }
  }
});
