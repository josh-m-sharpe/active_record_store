class ArStore < ActiveRecord::Base

  def write!(key, val)
    self.key   = key
    self.value = Marshal.dump(val)
    self.save!
    val
  end

  def self.read(key)
    r = get(key).try(:value)
    r ? Marshal.load(r) : nil
  end

  def self.write(key, value = nil, &blk)
    raise ArgumentError, "Pass value or a block, not both" if value && block_given?

    (get(key) || new).write!(key, value || yield)
  end

  def self.fetch(key, value = nil, &blk)
    raise ArgumentError, "Pass value or a block, not both" if value && block_given?
    read(key) || new.write!(key, value || yield)
  end

  def self.clean
    where(expired_arel).delete_all
  end

  def self.expired_arel
    arel_table[:updated_at].lt(EXPIRATION.ago)
  end

private

  def self.get(key)
    where(expired_arel.not).
    where(key: key).first
  end
end
