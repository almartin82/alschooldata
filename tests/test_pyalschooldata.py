"""
Tests for pyalschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyalschooldata
    assert pyalschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyalschooldata
    assert hasattr(pyalschooldata, 'fetch_enr')
    assert callable(pyalschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyalschooldata
    assert hasattr(pyalschooldata, 'get_available_years')
    assert callable(pyalschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyalschooldata
    assert hasattr(pyalschooldata, '__version__')
    assert isinstance(pyalschooldata.__version__, str)
