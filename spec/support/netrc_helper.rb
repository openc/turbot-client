module NetrcHelper
  def spec_open_netrc
    Netrc.read(Netrc.default_path)
  end

  def spec_save_netrc_entry(data)
    netrc = spec_open_netrc
    netrc['api.http://turbot.opencorporates.com'] = data
    netrc.save
  end

  def spec_delete_netrc_entry
    netrc = spec_open_netrc
    netrc.delete('api.http://turbot.opencorporates.com')
    netrc.save
  end

  def spec_read_netrc
    spec_open_netrc['api.http://turbot.opencorporates.com']
  end
end
