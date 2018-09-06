#!/usr/bin/python
# Runs tests against a live service to assert things are healthy
import re
import unittest
import argparse
import requests

def get_base_url():
    parser = argparse.ArgumentParser()
    parser.add_argument('base_url', help='base URL of the API to test, e.g. http://swarmapi.ausplots.aekos.org.au:3000')
    args = parser.parse_args()
    result = args.base_url
    print('Using base URL of %s' % result)
    return result


BASE_URL = get_base_url()

class TestUM(unittest.TestCase):

    def test_swagger_01(self):
        the_root = ''
        body = get_json(the_root)
        self.assertEqual(body['swagger'], '2.0')

    def test_site_01(self):
        item = get_single_element_json('site', 40, self)
        self.assertTrue(item['established_date'])

    def test_structural_summary_01(self):
        item = get_single_element_json('structural_summary', 13, self)
        self.assertTrue(item['phenology_comment'])

    def test_soil_bulk_density_01(self):
        item = get_single_element_json('soil_bulk_density', 13, self)
        self.assertTrue(item['sample_id'])

    def test_soil_characterisation_01(self):
        item = get_single_element_json('soil_characterisation', 32, self)
        self.assertTrue(item['upper_depth'])

    def test_soil_subsite_01(self):
        item = get_single_element_json('soil_subsite', 10, self)
        self.assertTrue(item['subsite_id'])

    def test_veg_voucher_01(self):
        item = get_single_element_json('veg_voucher', 11, self)
        self.assertTrue(item['veg_barcode'])

    def test_veg_pi_01(self):
        item = get_single_element_json('veg_pi', 11, self)
        self.assertTrue(item['point_number'])

    def test_veg_basal_01(self):
        item = get_single_element_json('veg_basal', 9, self)
        self.assertTrue(item['basal_area'])

def build_url(suffix):
    return '%s/%s' % (BASE_URL, suffix)

def get_json(suffix, params={}):
    resp = requests.get(build_url(suffix), params)
    resp.raise_for_status()
    body = resp.json()
    return body


def get_single_element_json(suffix, expected_field_count, unittest_self):
    body = get_json(suffix, params={'limit':'1'})
    unittest_self.assertEqual(len(body), 1)
    element1 = body[0]
    unittest_self.assertEqual(len(element1), expected_field_count, msg='Expected number of fields did not match')
    unittest_self.assertTrue(re.match('\w{6}\d{4}$', element1['site_location_name']), msg='Incorrect format for site_location_name')
    return element1


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestUM)
    unittest.TextTestRunner(verbosity=2).run(suite)
