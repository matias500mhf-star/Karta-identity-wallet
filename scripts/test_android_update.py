import unittest
from check_android_update import incompatibilities


class UpdatePrerequisites(unittest.TestCase):
    def test_compatible_upgrade(self):
        self.assertEqual(incompatibilities(('com.karta', 10, {'a'}), ('com.karta', 11, {'a'})), [])

    def test_fresh_ci_debug_key_is_blocked(self):
        self.assertTrue(incompatibilities(('com.karta', 10, {'old-key'}), ('com.karta', 11, {'new-key'})))

    def test_downgrade_and_same_version_are_blocked(self):
        for version in [9, 10]:
            self.assertTrue(incompatibilities(('com.karta', 10, {'a'}), ('com.karta', version, {'a'})))

    def test_different_app_is_not_an_update(self):
        self.assertTrue(incompatibilities(('com.karta', 10, {'a'}), ('other.app', 11, {'a'})))


if __name__ == '__main__':
    unittest.main()
